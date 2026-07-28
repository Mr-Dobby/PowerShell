# WMI-Report (20240513)
# by Gianni Bragante gbrag@microsoft.com

param( [string]$DataPath, [switch]$AcceptEula )

Function Get-WMINamespace($ns) {
  Write-Host $ns
  Get-WMIProviders $ns
  Get-Classes $ns
  Get-WmiNamespaceSecurity $ns
  Get-WmiObject -namespace $ns -class "__Namespace" | sort-object Name  |
  foreach {
    if ((($_.name.Length -le 2) -or ($_.name.Substring(0,3).ToLower() -ne "ms_")) -and (-not($_.name -match "LDAP"))) {
      Get-WMINamespace ($ns + "\" + $_.name)
    }
  }
}

Function Get-WMIProviders ($ns) {
  Get-WmiObject -NameSpace $ns -Class __Win32Provider | sort-object Name  |
  foreach {
    Get-ProvDetails $ns $_.name $_.CLSID $_.HostingModel $_.UnloadTimeout
  }
}

Function Get-Classes ($ns) {
  Get-WmiObject -Namespace $ns -Query "select * from meta_class" | sort-object Name  |
  foreach {
    $dynamic = $_.Qualifiers["dynamic"].Value
    $static = $_.Qualifiers["static"].Value

    if( $abstract -eq $true  -or $dynamic -eq $true ) {
      if ($dynamic -eq $true) { # Dynamic class
        $row = $tbDyn.NewRow()
        $row.NameSpace = $ns
        $row.Name = $_.name
        $row.Provider = $_.qualifiers["Provider"].value
        $tbDyn.Rows.Add($row)
      }
    } else {
      if (-not $_.name.Startswith("__")) {
        if ($static -eq $true) { # Static class = Repository
          $row = $tbStatic.NewRow()
          $row.NameSpace = $ns
          $row.Name = $_.name
          $row.Inst = $_.GetInstances().Count
          $row.Size = GetClassSize -className $_.name -ns $ns 
          $tbStatic.Rows.Add($row)
        } else {
          $row = $tbStatic.NewRow()
          $row.NameSpace = $ns
          $row.Name = $_.name

          $inst = $_.GetInstances().Count # Class with instances, repository as well
          if ($inst  -gt 0) {
            $row.Inst = $Inst
            $row.Size = GetClassSize -className $_.name -ns $ns 
          } else {
            $row.Inst = 0
            $row.Size = 0
          }

          $tbStatic.Rows.Add($row)
        }
      }
    }
  }
}

Function GetClassSize ($ns, $className) {
  $cSize = 0
  $classObj = Get-CimInstance -ClassName $className -Namespace $ns -ErrorAction SilentlyContinue
  if ($classObj) {
    ForEach ($inst in $classObj){
      ForEach($prop in $inst.CimInstanceProperties) {
        switch ($prop.CimType) {
          "SInt8" {$cSize += 1}
          "UInt8" {$cSize += 1}
          "SInt16" {$cSize += 2}
          "UInt16" {$cSize += 2}
          "SInt32" {$cSize += 4}
          "UInt32" {$cSize += 4}
          "SInt64" {$cSize += 8}
          "UInt64" {$cSize += 8}
          "Real32" {$cSize += 4}
          "Real64" {$cSize += 8}
          "Char16" {$cSize += 2}
          "Boolean" {$cSize += 1}
          "Datetime" {$cSize += 8}
          "String" {
            if ($prop.value) {
              $cSize += [Text.Encoding]::Unicode.GetByteCount($prop.value.ToString())
             }
          }
        }
      }
    }
  }
  return $cSize
}

Function Get-ProvDetails($ns, $name, $clsid, $HostingModel, $UnloadTimeout) {
  $row = $tbProv.NewRow()
  $row.NameSpace = $ns
  $row.Name = $name
  $row.HostingModel = $HostingModel
  $row.CLSID= $clsid
  $row.UnloadTimeout = $UnloadTimeout
  $dll = " "

  if ($clsid -ne $null) {
    if ($HostingModel -match "decoupled") {
      $Keys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Wbem\Transports\Decoupled\Client
      $Items = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }
      ForEach ($key in $Items) {
        if ($key.Provider -eq $name) {
          $key.ProcessIdentifier
          $proc = Get-WmiObject -Query ("select ExecutablePath from Win32_Process where ProcessId = " +  $key.ProcessIdentifier)
          $exe = get-item ($proc.ExecutablePath)
          $row.DLL = $proc.ExecutablePath
          $row.dtDLL = $exe.CreationTime
          $row.verDLL = $exe.VersionInfo.FileVersion
          $svc = Get-WmiObject -Query ("select Name from Win32_Service where ProcessId = " +  $key.ProcessIdentifier)
          if ($svc) {
            $row.ThreadingModel = ("Service: " + $svc.Name)
          }
        }
      }
    } elseif ($HostingModel -ne "SelfHost") {
      $name = (get-itemproperty -ErrorAction SilentlyContinue -literalpath ("HKCR:\CLSID\" + $clsid)).'(default)'
      $dll = (get-itemproperty -ErrorAction SilentlyContinue -literalpath ("HKCR:\CLSID\" + $clsid + "\InprocServer32")).'(default)'
      $row.DLL= $dll
      if ($dll) {
        $dll = $dll.Replace("""","")
        $file = Get-Item ($dll)
        $row.dtDLL = $file.CreationTime
        $row.verDLL = $file.VersionInfo.FileVersion
      }
      $row.ThreadingModel = (get-itemproperty -ErrorAction SilentlyContinue -literalpath ("HKCR:\CLSID\" + $clsid + "\InprocServer32")).'ThreadingModel'
    }
  }
  $tbProv.Rows.Add($row)
}

Function Get-WmiNamespaceSecurity {
    # This function comes from https://github.com/KurtDeGreeff/PlayPowershell/blob/master/Get-WmiNamespaceSecurity.ps1
    Param ( [parameter(Mandatory=$true,Position=0)][string] $namespace,
        [string] $computer = ".",
        [System.Management.Automation.PSCredential] $credential = $null)
 
    Process {
        $ErrorActionPreference = "Stop"
 
        Function Get-PermissionFromAccessMask($accessMask) {
            $WBEM_ENABLE            = 1
            $WBEM_METHOD_EXECUTE         = 2
            $WBEM_FULL_WRITE_REP           = 4
            $WBEM_PARTIAL_WRITE_REP     = 8
            $WBEM_WRITE_PROVIDER          = 0x10
            $WBEM_REMOTE_ACCESS            = 0x20
            $READ_CONTROL = 0x20000
            $WRITE_DAC = 0x40000
       
            $WBEM_RIGHTS_FLAGS = $WBEM_ENABLE,$WBEM_METHOD_EXECUTE,$WBEM_FULL_WRITE_REP,`
                $WBEM_PARTIAL_WRITE_REP,$WBEM_WRITE_PROVIDER,$WBEM_REMOTE_ACCESS,`
                $WBEM_RIGHT_SUBSCRIBE,$WBEM_RIGHT_PUBLISH,$READ_CONTROL,$WRITE_DAC
            $WBEM_RIGHTS_STRINGS = "EnableAccount","ExecuteMethod","FullWrite","PartialWrite",`
                "ProviderWrite","RemoteEnable","Subscribe","Publish","ReadSecurity","WriteSecurity"
 
            $permission = @()
            for ($i = 0; $i -lt $WBEM_RIGHTS_FLAGS.Length; $i++) {
                if (($accessMask -band $WBEM_RIGHTS_FLAGS[$i]) -gt 0) {
                    $permission += $WBEM_RIGHTS_STRINGS[$i]
                }
            }
       
            $permission
        }

        $res = "" 
        $INHERITED_ACE_FLAG = 0x10
 
        $invokeparams = @{Namespace=$namespace;Path="__systemsecurity=@";Name="GetSecurityDescriptor";ComputerName=$computer}
 
        if ($credential -eq $null) {
            $credparams = @{}
        } else {
            $credparams = @{Credential=$credential}
        }
 
        $output = Invoke-WmiMethod @invokeparams @credparams -ErrorAction SilentlyContinue
        if ($output.ReturnValue -ne 0) {
            $res = "GetSecurityDescriptor failed:" + $output.ReturnValue + "   "
        }
   
        $acl = $output.Descriptor
        foreach ($ace in $acl.DACL) {
            $user = New-Object System.Management.Automation.PSObject
            $user | Add-Member -MemberType NoteProperty -Name "Name" -Value "$($ace.Trustee.Domain)\$($ace.Trustee.Name)"
            $user | Add-Member -MemberType NoteProperty -Name "Permission" -Value (Get-PermissionFromAccessMask($ace.AccessMask))
            $user | Add-Member -MemberType NoteProperty -Name "Inherited" -Value (($ace.AceFlags -band $INHERITED_ACE_FLAG) -gt 0)
            $res = $res + ($user.Name + " (" + ($user.permission -join " ") + ")") + " / "
        }
        $row = $tbSec.NewRow()
        $row.NameSpace = $namespace
        $row.Security = $res.Substring(0, $res.Length -3)
        $tbSec.Rows.Add($row)
    }
}

[void][System.Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][System.Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')

function ShowEULAPopup($mode)
{
    $EULA = New-Object -TypeName System.Windows.Forms.Form
    $richTextBox1 = New-Object System.Windows.Forms.RichTextBox
    $btnAcknowledge = New-Object System.Windows.Forms.Button
    $btnCancel = New-Object System.Windows.Forms.Button

    $EULA.SuspendLayout()
    $EULA.Name = "EULA"
    $EULA.Text = "Microsoft Diagnostic Tools End User License Agreement"

    $richTextBox1.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $richTextBox1.Location = New-Object System.Drawing.Point(12,12)
    $richTextBox1.Name = "richTextBox1"
    $richTextBox1.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
    $richTextBox1.Size = New-Object System.Drawing.Size(776, 397)
    $richTextBox1.TabIndex = 0
    $richTextBox1.ReadOnly=$True
    $richTextBox1.Add_LinkClicked({Start-Process -FilePath $_.LinkText})
    $richTextBox1.Rtf = @"
{\rtf1\ansi\ansicpg1252\deff0\nouicompat{\fonttbl{\f0\fswiss\fprq2\fcharset0 Segoe UI;}{\f1\fnil\fcharset0 Calibri;}{\f2\fnil\fcharset0 Microsoft Sans Serif;}}
{\colortbl ;\red0\green0\blue255;}
{\*\generator Riched20 10.0.19041}{\*\mmathPr\mdispDef1\mwrapIndent1440 }\viewkind4\uc1 
\pard\widctlpar\f0\fs19\lang1033 MICROSOFT SOFTWARE LICENSE TERMS\par
Microsoft Diagnostic Scripts and Utilities\par
\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15 
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}These license terms are an agreement between you and Microsoft Corporation (or one of its affiliates). IF YOU COMPLY WITH THESE LICENSE TERMS, YOU HAVE THE RIGHTS BELOW. BY USING THE SOFTWARE, YOU ACCEPT THESE TERMS.\par
{\pict{\*\picprop}\wmetafile8\picw26\pich26\picwgoal32000\pichgoal15 
0100090000035000000000002700000000000400000003010800050000000b0200000000050000
000c0202000200030000001e000400000007010400040000000701040027000000410b2000cc00
010001000000000001000100000000002800000001000000010000000100010000000000000000
000000000000000000000000000000000000000000ffffff00000000ff040000002701ffff0300
00000000
}\par
\pard 
{\pntext\f0 1.\tab}{\*\pn\pnlvlbody\pnf0\pnindent0\pnstart1\pndec{\pntxta.}}
\fi-360\li360 INSTALLATION AND USE RIGHTS. Subject to the terms and restrictions set forth in this license, Microsoft Corporation (\ldblquote Microsoft\rdblquote ) grants you (\ldblquote Customer\rdblquote  or \ldblquote you\rdblquote ) a non-exclusive, non-assignable, fully paid-up license to use and reproduce the script or utility provided under this license (the "Software"), solely for Customer\rquote s internal business purposes, to help Microsoft troubleshoot issues with one or more Microsoft products, provided that such license to the Software does not include any rights to other Microsoft technologies (such as products or services). \ldblquote Use\rdblquote  means to copy, install, execute, access, display, run or otherwise interact with the Software. \par
\pard\widctlpar\par
\pard\widctlpar\li360 You may not sublicense the Software or any use of it through distribution, network access, or otherwise. Microsoft reserves all other rights not expressly granted herein, whether by implication, estoppel or otherwise. You may not reverse engineer, decompile or disassemble the Software, or otherwise attempt to derive the source code for the Software, except and to the extent required by third party licensing terms governing use of certain open source components that may be included in the Software, or remove, minimize, block, or modify any notices of Microsoft or its suppliers in the Software. Neither you nor your representatives may use the Software provided hereunder: (i) in a way prohibited by law, regulation, governmental order or decree; (ii) to violate the rights of others; (iii) to try to gain unauthorized access to or disrupt any service, device, data, account or network; (iv) to distribute spam or malware; (v) in a way that could harm Microsoft\rquote s IT systems or impair anyone else\rquote s use of them; (vi) in any application or situation where use of the Software could lead to the death or serious bodily injury of any person, or to physical or environmental damage; or (vii) to assist, encourage or enable anyone to do any of the above.\par
\par
\pard\widctlpar\fi-360\li360 2.\tab DATA. Customer owns all rights to data that it may elect to share with Microsoft through using the Software. You can learn more about data collection and use in the help documentation and the privacy statement at {{\field{\*\fldinst{HYPERLINK https://aka.ms/privacy }}{\fldrslt{https://aka.ms/privacy\ul0\cf0}}}}\f0\fs19 . Your use of the Software operates as your consent to these practices.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 3.\tab FEEDBACK. If you give feedback about the Software to Microsoft, you grant to Microsoft, without charge, the right to use, share and commercialize your feedback in any way and for any purpose.\~ You will not provide any feedback that is subject to a license that would require Microsoft to license its software or documentation to third parties due to Microsoft including your feedback in such software or documentation. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 4.\tab EXPORT RESTRICTIONS. Customer must comply with all domestic and international export laws and regulations that apply to the Software, which include restrictions on destinations, end users, and end use. For further information on export restrictions, visit {{\field{\*\fldinst{HYPERLINK https://aka.ms/exporting }}{\fldrslt{https://aka.ms/exporting\ul0\cf0}}}}\f0\fs19 .\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 5.\tab REPRESENTATIONS AND WARRANTIES. Customer will comply with all applicable laws under this agreement, including in the delivery and use of all data. Customer or a designee agreeing to these terms on behalf of an entity represents and warrants that it (i) has the full power and authority to enter into and perform its obligations under this agreement, (ii) has full power and authority to bind its affiliates or organization to the terms of this agreement, and (iii) will secure the permission of the other party prior to providing any source code in a manner that would subject the other party\rquote s intellectual property to any other license terms or require the other party to distribute source code to any of its technologies.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360\qj 6.\tab DISCLAIMER OF WARRANTY. THE SOFTWARE IS PROVIDED \ldblquote AS IS,\rdblquote  WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL MICROSOFT OR ITS LICENSORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\par
\pard\widctlpar\qj\par
\pard\widctlpar\fi-360\li360\qj 7.\tab LIMITATION ON AND EXCLUSION OF DAMAGES. IF YOU HAVE ANY BASIS FOR RECOVERING DAMAGES DESPITE THE PRECEDING DISCLAIMER OF WARRANTY, YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT, OR INCIDENTAL DAMAGES. This limitation applies to (i) anything related to the Software, services, content (including code) on third party Internet sites, or third party applications; and (ii) claims for breach of contract, warranty, guarantee, or condition; strict liability, negligence, or other tort; or any other claim; in each case to the extent permitted by applicable law. It also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your state, province, or country may not allow the exclusion or limitation of incidental, consequential, or other damages.\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 8.\tab BINDING ARBITRATION AND CLASS ACTION WAIVER. This section applies if you live in (or, if a business, your principal place of business is in) the United States.  If you and Microsoft have a dispute, you and Microsoft agree to try for 60 days to resolve it informally. If you and Microsoft can\rquote t, you and Microsoft agree to binding individual arbitration before the American Arbitration Association under the Federal Arbitration Act (\ldblquote FAA\rdblquote ), and not to sue in court in front of a judge or jury. Instead, a neutral arbitrator will decide. Class action lawsuits, class-wide arbitrations, private attorney-general actions, and any other proceeding where someone acts in a representative capacity are not allowed; nor is combining individual proceedings without the consent of all parties. The complete Arbitration Agreement contains more terms and is at {{\field{\*\fldinst{HYPERLINK https://aka.ms/arb-agreement-4 }}{\fldrslt{https://aka.ms/arb-agreement-4\ul0\cf0}}}}\f0\fs19 . You and Microsoft agree to these terms. \par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 9.\tab LAW AND VENUE. If U.S. federal jurisdiction exists, you and Microsoft consent to exclusive jurisdiction and venue in the federal court in King County, Washington for all disputes heard in court (excluding arbitration). If not, you and Microsoft consent to exclusive jurisdiction and venue in the Superior Court of King County, Washington for all disputes heard in court (excluding arbitration).\par
\pard\widctlpar\par
\pard\widctlpar\fi-360\li360 10.\tab ENTIRE AGREEMENT. This agreement, and any other terms Microsoft may provide for supplements, updates, or third-party applications, is the entire agreement for the software.\par
\pard\sa200\sl276\slmult1\f1\fs22\lang9\par
\pard\f2\fs17\lang2057\par
}
"@
    $richTextBox1.BackColor = [System.Drawing.Color]::White
    $btnAcknowledge.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnAcknowledge.Location = New-Object System.Drawing.Point(544, 415)
    $btnAcknowledge.Name = "btnAcknowledge";
    $btnAcknowledge.Size = New-Object System.Drawing.Size(119, 23)
    $btnAcknowledge.TabIndex = 1
    $btnAcknowledge.Text = "Accept"
    $btnAcknowledge.UseVisualStyleBackColor = $True
    $btnAcknowledge.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::Yes})

    $btnCancel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $btnCancel.Location = New-Object System.Drawing.Point(669, 415)
    $btnCancel.Name = "btnCancel"
    $btnCancel.Size = New-Object System.Drawing.Size(119, 23)
    $btnCancel.TabIndex = 2
    if($mode -ne 0)
    {
	    $btnCancel.Text = "Close"
    }
    else
    {
	    $btnCancel.Text = "Decline"
    }
    $btnCancel.UseVisualStyleBackColor = $True
    $btnCancel.Add_Click({$EULA.DialogResult=[System.Windows.Forms.DialogResult]::No})

    $EULA.AutoScaleDimensions = New-Object System.Drawing.SizeF(6.0, 13.0)
    $EULA.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $EULA.ClientSize = New-Object System.Drawing.Size(800, 450)
    $EULA.Controls.Add($btnCancel)
    $EULA.Controls.Add($richTextBox1)
    if($mode -ne 0)
    {
	    $EULA.AcceptButton=$btnCancel
    }
    else
    {
        $EULA.Controls.Add($btnAcknowledge)
	    $EULA.AcceptButton=$btnAcknowledge
        $EULA.CancelButton=$btnCancel
    }
    $EULA.ResumeLayout($false)
    $EULA.Size = New-Object System.Drawing.Size(800, 650)

    Return ($EULA.ShowDialog())
}

function ShowEULAIfNeeded($toolName, $mode)
{
	$eulaRegPath = "HKCU:Software\Microsoft\CESDiagnosticTools"
	$eulaAccepted = "No"
	$eulaValue = $toolName + " EULA Accepted"
	if(Test-Path $eulaRegPath)
	{
		$eulaRegKey = Get-Item $eulaRegPath
		$eulaAccepted = $eulaRegKey.GetValue($eulaValue, "No")
	}
	else
	{
		$eulaRegKey = New-Item $eulaRegPath
	}
	if($mode -eq 2) # silent accept
	{
		$eulaAccepted = "Yes"
       		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
	}
	else
	{
		if($eulaAccepted -eq "No")
		{
			$eulaAccepted = ShowEULAPopup($mode)
			if($eulaAccepted -eq [System.Windows.Forms.DialogResult]::Yes)
			{
	        		$eulaAccepted = "Yes"
	        		$ignore = New-ItemProperty -Path $eulaRegPath -Name $eulaValue -Value $eulaAccepted -PropertyType String -Force
			}
		}
	}
	return $eulaAccepted
}

$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-not $myWindowsPrincipal.IsInRole($adminRole)) {
  Write-Output "This script needs to be run as Administrator"
  exit
}

$global:Root = Split-Path (Get-Variable MyInvocation).Value.MyCommand.Path

$resName = "WMI-Report-" + $env:computername +"-" + $(get-date -f yyyyMMdd_HHmmss)
$global:resDir = $global:Root + "\" + $resName

if ($AcceptEula) {
  Write-Host "AcceptEula switch specified, silently continuing"
  $eulaAccepted = ShowEULAIfNeeded "WMI-Report" 2
} else {
  $eulaAccepted = ShowEULAIfNeeded "WMI-Report" 0
  if($eulaAccepted -ne "Yes")
  {
    Write-Host "EULA declined, exiting"
    exit
  }
}
Write-Host "EULA accepted, continuing"

if ($DataPath) {
  if (-not (Test-Path $DataPath)) {
    Write-Host "The folder $DataPath does not exist"
    exit
  }
  $global:resDir = $DataPath + "\" + $resName
} else {
  $global:resDir = $global:Root + "\" + $resName
}

New-Item -itemtype directory -path $global:resDir | Out-Null

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null

$tbProv = New-Object system.Data.DataTable "WmiProv"
$col = New-Object system.Data.DataColumn NameSpace,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn Name,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn HostingModel,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn ThreadingModel,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn DLL,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn dtDLL,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn verDLL,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn UnloadTimeout,([string])
$tbProv.Columns.Add($col)
$col = New-Object system.Data.DataColumn CLSID,([string])
$tbProv.Columns.Add($col)

$tbDyn = New-Object system.Data.DataTable "Classes"
$col = New-Object system.Data.DataColumn NameSpace,([string])
$tbDyn.Columns.Add($col)
$col = New-Object system.Data.DataColumn Name,([string])
$tbDyn.Columns.Add($col)
$col = New-Object system.Data.DataColumn Provider,([string])
$tbDyn.Columns.Add($col)

$tbStatic = New-Object system.Data.DataTable "Repository"
$col = New-Object system.Data.DataColumn NameSpace,([string])
$tbStatic.Columns.Add($col)
$col = New-Object system.Data.DataColumn Name,([string])
$tbStatic.Columns.Add($col)
$col = New-Object system.Data.DataColumn Inst,([Int32])
$tbStatic.Columns.Add($col)
$col = New-Object system.Data.DataColumn Size,([Int64])
$tbStatic.Columns.Add($col)

$tbSec = New-Object system.Data.DataTable "Security"
$col = New-Object system.Data.DataColumn NameSpace,([string])
$tbSec.Columns.Add($col)
$col = New-Object system.Data.DataColumn Security,([string])
$tbSec.Columns.Add($col)


Get-WMINamespace "Root"

Write-Host "Writing Providers.csv"
$tbProv | Export-Csv $global:resDir"\Providers.csv" -noType
Write-Host "Writing Classes.csv"
$tbDyn | Export-Csv $global:resDir"\Dynamic.csv" -noType
Write-Host "Writing Repository.csv"
$tbStatic | Export-Csv $global:resDir"\Static.csv" -noType
Write-Host "Writing Security.csv"
$tbSec | Export-Csv $global:resDir"\Security.csv" -noType

# SIG # Begin signature block
# MIIoOAYJKoZIhvcNAQcCoIIoKTCCKCUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvDosdHCUJOkpL
# Y6V9rugF1i7srSeeFU6RbSEbTj21yqCCDYUwggYDMIID66ADAgECAhMzAAADri01
# UchTj1UdAAAAAAOuMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwODU5WhcNMjQxMTE0MTkwODU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQD0IPymNjfDEKg+YyE6SjDvJwKW1+pieqTjAY0CnOHZ1Nj5irGjNZPMlQ4HfxXG
# yAVCZcEWE4x2sZgam872R1s0+TAelOtbqFmoW4suJHAYoTHhkznNVKpscm5fZ899
# QnReZv5WtWwbD8HAFXbPPStW2JKCqPcZ54Y6wbuWV9bKtKPImqbkMcTejTgEAj82
# 6GQc6/Th66Koka8cUIvz59e/IP04DGrh9wkq2jIFvQ8EDegw1B4KyJTIs76+hmpV
# M5SwBZjRs3liOQrierkNVo11WuujB3kBf2CbPoP9MlOyyezqkMIbTRj4OHeKlamd
# WaSFhwHLJRIQpfc8sLwOSIBBAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhx/vdKmXhwc4WiWXbsf0I53h8T8w
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMTgzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AGrJYDUS7s8o0yNprGXRXuAnRcHKxSjFmW4wclcUTYsQZkhnbMwthWM6cAYb/h2W
# 5GNKtlmj/y/CThe3y/o0EH2h+jwfU/9eJ0fK1ZO/2WD0xi777qU+a7l8KjMPdwjY
# 0tk9bYEGEZfYPRHy1AGPQVuZlG4i5ymJDsMrcIcqV8pxzsw/yk/O4y/nlOjHz4oV
# APU0br5t9tgD8E08GSDi3I6H57Ftod9w26h0MlQiOr10Xqhr5iPLS7SlQwj8HW37
# ybqsmjQpKhmWul6xiXSNGGm36GarHy4Q1egYlxhlUnk3ZKSr3QtWIo1GGL03hT57
# xzjL25fKiZQX/q+II8nuG5M0Qmjvl6Egltr4hZ3e3FQRzRHfLoNPq3ELpxbWdH8t
# Nuj0j/x9Crnfwbki8n57mJKI5JVWRWTSLmbTcDDLkTZlJLg9V1BIJwXGY3i2kR9i
# 5HsADL8YlW0gMWVSlKB1eiSlK6LmFi0rVH16dde+j5T/EaQtFz6qngN7d1lvO7uk
# 6rtX+MLKG4LDRsQgBTi6sIYiKntMjoYFHMPvI/OMUip5ljtLitVbkFGfagSqmbxK
# 7rJMhC8wiTzHanBg1Rrbff1niBbnFbbV4UDmYumjs1FIpFCazk6AADXxoKCo5TsO
# zSHqr9gHgGYQC2hMyX9MGLIpowYCURx3L7kUiGbOiMwaMIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGgkwghoFAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAOuLTVRyFOPVR0AAAAA
# A64wDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAiH
# NQTNcjA6Bo7C3sZShubpH30p8Tz28F6g+3ErcHMrMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAS23f0z7TFi4bjSksHY3KXV1wfBve7AlLJU9c
# zi1qrCNTrzk6JkZ886GoU0qr+m2YjfZYmpZvx9QP2aVLZSBDPFGs2vYVj5El07sv
# +CRFEGANEw/A99WLLnwMQHm7CTiu4KPxdCSuq+l+QHMlom+g3l7sjaaNkuPOONl7
# g2XBOhPwMABUMWrVSuo9TUUxBgrj/oVnTWlODQNSv7dUH2MP39by7CT6DDZCAYRh
# kpuS6LD7c5Ndh0cNOr+qtqLR4gfI30PXNNh0+EAPm1CL1I5JRd7VPzmEGhHpyy7h
# DuBrDnN08+QE5tkpAgwoi4J2qNa6fkx/ZleoLgZJY9Gbj/Q7oKGCF5MwghePBgor
# BgEEAYI3AwMBMYIXfzCCF3sGCSqGSIb3DQEHAqCCF2wwghdoAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFRBgsqhkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCCnXKLT/4yesJ3d+S1KJSBGVVqDbyZKbjqR
# 2BjXvygO0wIGZkZX1jEqGBIyMDI0MDYxMjE1MDA0MC4xMVowBIACAfSggdGkgc4w
# gcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
# HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQg
# VFNTIEVTTjozMzAzLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCEeowggcgMIIFCKADAgECAhMzAAAB5tlCnuoA+H3hAAEA
# AAHmMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTIzMTIwNjE4NDUxNVoXDTI1MDMwNTE4NDUxNVowgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjozMzAzLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL2+mHzi2CW4TOb/Ck0qUCNw
# SUbN+W8oANnUP7Z3+J5hgS0XYcoysoYUM4uktZYbkMTKIpuVgqsTae3njQ4a7fln
# HSBckETTNZqdkQCMKO3h4YGL65qRmyTvTMdNAcfJ8/4HebYFJI0U+GCxUg+nq+j/
# 23o5417MjBfkTn5XAQbfudmAR7FAXZ9BlhvFDUBq6oO9F1exKkrV2HVQG30RoyzO
# 65xpHmczBA3qwOMb30XN0r0C3NufhKaWygtS1ECH/vrywp3RjWEyYpUfAhfz/gm5
# RFQFFnQla7Q1hAGnySGS7XxDwIBDnTS0UHtUfekPzOgDiVwDsmTFMag8qu5+b6VF
# kADiIyBtwtnY//FJ2coXFTy8vfVGg2VkmIYvkypNe+/IEvP4xE/gSf03J7U3zH+U
# kPWy102jnAkb6aBewT/N/ODYZpWpBzMUeDQ2Xxukiqc0VRF5BGrcLWNVgwJJx6A3
# Md5i3Dk6Zn/t5WdGaNeUKwu92zE7NzVhWfqdkuRAPnLfUdisH2Ige6zCFoy/aEk0
# 2NWd2SlbL3fg8hm5ZMyTfrSSNc8XCXZa/VPOb206sKrz6XjTwogvon55+gY2RHxg
# Hcz67W1h5UM79Nw5sYfFoYUHpBnEBSmd8Hk38yYE3Ew6rMbU3xCLBbyC2OMwmIUF
# /qJhisKO1HAXsg91AsW1AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQU5QQxee03nj7X
# Vkz5C7tDmuDcVz0wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYD
# VR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# cmwvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwG
# CCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIw
# MjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwDQYJKoZIhvcNAQELBQADggIBAGFu6iBNqlGy7BKR
# oUxDp3K7xkJhSlZDyIituLjS1TaErqkeC7SGPTP/3MVFHHkN+G6SO9uMD91LlVh/
# HPUQhs+W3z3swnawEY7ZgtjBh6V8mkPBsHRdL1mSuqnOrpf+WYNAOfcbm9xilhAI
# nnksu/IWUnX3kBWjhbLxRfmnuD1bcyA0dAykz4RXrj5yzOPgejlpCZ4oa0rLvDvZ
# 5Fj+9YO6m2u/Ou4U2YoIi3XZRwDkE6xenU+2SPHbJGwKPvsNKaXTNViOpb8hJaSs
# aPJ5Un6SHNy3FouSSVXALGKCiQPp+RZvLSEIQpM5M8zOG6A8gBzFwexHazHTVhFr
# 2kfbO912y4ER9IUboKPRBK8Rn8z2Yn6HiaJpBJHsARtUYNvJEqRifzRL7cCZGWHd
# k574EWonns5d14gNIdu8fMnuhOobz3qXd5SE+xmDr182DFPGW9E2ZET/7rViPtnW
# 4HRdhA/rSuwwt1OVVgTJlSXkwtMvku+oWjNmVLZeiOLgEQ/p11VPOYcnih05kxZN
# N5DQjCdYb3y9a/+ug96AKvUbrUVWt1csTcBch+3hk3hmQNOegCE/DsNk09GVJbhN
# tWP8vDRe+ctg3AxQD2i5j/DH215Nony9ORuBjJo5goXPqs1Fdnhp/p7chfAwJ98J
# qykpRcLvZgy7lbwv/PJPGw1QSAFtMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
# mQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
# Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
# dCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1
# WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjK
# NVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhg
# fWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJp
# rx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/d
# vI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka9
# 7aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKR
# Hh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9itu
# qBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyO
# ArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItb
# oKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6
# bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6t
# AgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQW
# BBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacb
# UzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYz
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
# aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2
# VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/q
# XBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6
# U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVt
# I1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis
# 9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTp
# kbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0
# sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138e
# W0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJ
# sWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7
# Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0
# dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQ
# tB1VM1izoXBm8qGCA00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmlj
# YSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046MzMwMy0wNUUw
# LUQ5NDcxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
# ATAHBgUrDgMCGgMVAOJY0F4Un2O9oSs3rgPUbzp4vSa7oIGDMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqE8QlMCIY
# DzIwMjQwNjEyMDY1MjIxWhgPMjAyNDA2MTMwNjUyMjFaMHQwOgYKKwYBBAGEWQoE
# ATEsMCowCgIFAOoTxCUCAQAwBwIBAAICDMswBwIBAAICE30wCgIFAOoVFaUCAQAw
# NgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgC
# AQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEAgCUXjxDOUjT+dQcTfT0iftF7fAwy
# wZWMm8fxDIMVKB2jFruICaZuPFIcOPpE5aSkL6nAKH7maea3I5j6qA8kRkRx68ZA
# 6wwCDFIPCAWSMaMs4fXQA0wam/guCh9/XmhXSSDz69bbD+ILOZrN6euj8pTazqNn
# btylnU7FbBOFp+wShlodwBWtHmW2QkTFwSBLF8ucVMT1yK2Vj8UZ8k8Cg8sCt/1q
# z0x6zFmueHBLVF13jrN9rZH9a3+x4qB7xokcQl+zdBHHgz6GFBRUGezJSswibEy9
# dNb3DjjZDr7pFNJlvx62ZhpAuYW63V0+tOS8W0wfYH9Jx8BLHWOckvPNjjGCBA0w
# ggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5tlC
# nuoA+H3hAAEAAAHmMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYL
# KoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIEK7Nvu4Lfrta0irsUF8N5ec6iAS
# VN6MrPXihjJA6rWfMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgz7ujhqge
# swlobyCcs7WrXqEhhxGejLoWc4JudIPSxlkwgZgwgYCkfjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAebZQp7qAPh94QABAAAB5jAiBCDLoqZJoRFQ
# XDnMzyLGtaN50RasKRdgbT7wlAFFD4YlcjANBgkqhkiG9w0BAQsFAASCAgAchMRC
# 9fbGPRXJ73xrjHYkgwW+eiv4FJp8cIxnjfikK4uzco290g1reQKrrPW93dsbDuFf
# zGQZvZjWGD41tQaO6HEmE/VYE/zl2xobeCs8k3tKO7O3La4nTe2i3KY9FsfBmjfL
# TfY3a09LXu9TqposBI+YJAJ8EMbH6a9m1s2izQ3k6QIj/2T5kVsRm8Fz7kQbjFDU
# VqQlaZw9pOqOf6T4VFRJVL9sWgAHb88IyuHrqsHCx9+PfjXakF8bqMhrEpamIJId
# u2QUxVse0TuYUsvNLiBzATVqhfUJdGo7p8UAO7oslCXHbUHAZY5jKmWKLAkrRGwL
# tv/vtZrG30mZM8Lwq8jZKx2S1S5hBG1X3sRb0QImyz5SlLc35LdSJx8GoUmycyw+
# v3qMcZyOc9kiklQKvUVpYdcxXj8SuqwKfd21ay65JbxhIdThdMURa+TvlVvNIaFG
# Cxxo0z9rQGKlLjuyC/tGIisTb1kfroRZgpokNHvJR+D7zzefooDchfzdE0YmsUqd
# fiNEOQoWYDfniNzAszyqYi4p8QVo8lsTJlFBnyddiIWr6exrduk3R1ivP7rQpRGl
# WUiBUgh9ACHc7IvQKsK822DjfCjY8PawXAIeU/Y34tYBHH1ygDFEC8K3S1JozTTz
# 0fIx0hcciZeIlVbhKFHKA8BVxGWq+/75gZHmMQ==
# SIG # End signature block
