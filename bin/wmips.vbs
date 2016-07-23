' wmips.vbs
'
' #ident @(#) $Header: /package/cvs/exploitation/sbin/Attic/wmips.vbs,v 1.1.2.2 2010/01/25 15:27:15 cle Exp $
' Copyright (c) 2009-2016 Cyrille Lefevre (Cyrille.Lefevre@laposte.net). All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions
' are met:
'
' 1. Redistributions of source code must retain the above copyright
'    notice, this list of conditions and the following disclaimer.
' 2. Redistributions in binary form must reproduce the above copyright
'    notice, this list of conditions and the following disclaimer in
'    the documentation and/or other materials provided with the
'    distribution.
'
' THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS''
' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
' TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
' PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS
' OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
' SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
' LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
' USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
' ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
' OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
' OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
' SUCH DAMAGE.

Option Explicit

Dim strComputer, strUser, strDomain, strCommandLine
Dim objWMIService, dtmSWbemDateTime
Dim colOperatingSystemList, objOperatingSystem
Dim colProcessList, objProcess, colProperties
Dim colServiceList, objService
Dim colPerformanceList, objPerformance

strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

'Set dtmSWbemDateTime = CreateObject("WbemScripting.SWbemDateTime")

objWMIService.Security_.ImpersonationLevel = 3
objWMIService.Security_.privileges.addasstring "SeDebugPrivilege", True 

Set colOperatingSystemList = objWMIService.ExecQuery( _
	"Select * from Win32_OperatingSystem")

For Each objOperatingSystem in colOperatingSystemList
	'dtmSWbemDateTime.Value = objOperatingSystem.LastBootUpTime
	Wscript.Echo "LastBootUpTime " & objOperatingSystem.LastBootUpTime
	Wscript.Echo "LocalDateTime " & objOperatingSystem.LocalDateTime
	Wscript.Echo "TotalVisibleMemorySize " & _
		objOperatingSystem.TotalVisibleMemorySize
Next

set objOperatingSystem = Nothing
set colOperatingSystemList = Nothing

Set colServiceList = objWMIService.ExecQuery( _
	"Select * from Win32_Service where ProcessId <> 0")

Wscript.Echo "ProcessId DesktopInteract ServiceName"

For Each objService in colServiceList
	Wscript.Echo _
		objService.ProcessId & _
		" " & _
		objService.DesktopInteract & _
		" """ & _
		objService.Name & _
		""" "
Next

Set colServiceList = Nothing

' Set colPerformanceList = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfProc_Process")
' 
' Wscript.Echo "ProcessId ElapsedTime PercentProcessorTime PrivateBytes WorkingSetPrivate"
' 
' For Each objPerformance in colPerformanceList
' 	Wscript.Echo _
' 		objPerformance.IdProcess & _
' 		" " & _
' 		objPerformance.ElapsedTime & _
' 		" " & _
' 		objPerformance.PercentProcessorTime & _
' 		" " & _
' 		objPerformance.PrivateBytes & _
' 		" " & _
' 		objPerformance.WorkingSetPrivate
' Next
' 
' Set colPerformanceList = Nothing

Set colProcessList = objWMIService.ExecQuery("Select * from Win32_Process")

Wscript.Echo "UserName ProcessId ParentProcessId Priority CreationDate" & _
	" SessionId KernelModeTime UserModeTime PrivatePageCount" & _
	" VirtualSize WorkingSetSize ProcessName ExecutablePath CommandLine"

For Each objProcess in colProcessList
	WScript.Interactive = false
	colProperties = objProcess.GetOwner(strUser,strDomain)
	WScript.Interactive = true
	strCommandLine = objProcess.CommandLine
	If strCommandLine <> vbNull And InStr(strCommandLine, vbLf) <> 0 Then
		strCommandLine = Replace(strCommandLine, vbLf, "\n")
		if InStr(strCommandLine, vbCr) <> 0 Then
			strCommandLine = Replace(strCommandLine, vbCr, "\r")
		End If
	End If
	Wscript.Echo _
		"""" & _
		strUser & _
		""" " & _
		objProcess.ProcessId & _
		" " & _
		objProcess.ParentProcessId & _
		" " & _
		objProcess.Priority & _
		" " & _
		objProcess.CreationDate & _
		" " & _
		objProcess.SessionId & _
		" " & _
		objProcess.KernelModeTime & _
		" " & _
		objProcess.UserModeTime & _
		" " & _
		objProcess.PrivatePageCount & _
		" " & _
		objProcess.VirtualSize & _
		" " & _
		objProcess.WorkingSetSize & _
		" """ & _
		objProcess.Name & _
		""" """ & _
		objProcess.ExecutablePath & _
		""" " & _
		strCommandLine
Next

Set colProperties = Nothing
Set colProcessList = Nothing

Set objWMIService = Nothing

' eof
