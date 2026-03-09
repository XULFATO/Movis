' ============================================================
'  AlinarColumnasDyE_Derecha_Color
'  Alinea las columnas D y E basándose en el valor a la DERECHA del #
'  Reglas: RH -> 100+valor, R -> omitir.
'  EXTRA: Marca en ROJO las celdas que no tienen pareja.
' ============================================================

Option Explicit

Const FILA_CABECERA  As Long = 1
Const FILA_DATOS     As Long = 2
Const COL_LIMITE_D   As Long = 4   ' Columnas A-D = lado D; E en adelante = lado E

' ------------------------------------------------------------
Sub AlinarColumnasDyE()
' ------------------------------------------------------------
    Dim wsOrigen  As Worksheet
    Dim wsResult  As Worksheet
    Set wsOrigen = ActiveSheet

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    ' --- Crear / limpiar hoja de resultado ---
    Dim nombreHoja As String: nombreHoja = "Resultado_D_E"
    On Error Resume Next
    Application.DisplayAlerts = False
    Sheets(nombreHoja).Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    Set wsResult = Sheets.Add(After:=wsOrigen)
    wsResult.Name = nombreHoja

    ' --- Dimensiones del origen ---
    Dim ultFila As Long, ultCol As Long
    ultFila = wsOrigen.Cells(wsOrigen.Rows.Count, "D").End(xlUp).Row
    ultCol = wsOrigen.Cells(FILA_CABECERA, wsOrigen.Columns.Count).End(xlToLeft).Column

    If ultFila < FILA_DATOS Then
        MsgBox "No hay datos suficientes.", vbExclamation
        Exit Sub
    End If

    ' Copiar cabecera
    wsOrigen.Rows(FILA_CABECERA).Copy wsResult.Rows(1)

    Dim nFilas As Long: nFilas = ultFila - FILA_DATOS + 1
    Dim datos As Variant
    datos = wsOrigen.Range(wsOrigen.Cells(FILA_DATOS, 1), wsOrigen.Cells(ultFila, ultCol)).Value

    ' --- Extraer y procesar valores de la DERECHA de D (4) y E (5) ---
    Dim valD() As String, valE() As String
    ReDim valD(1 To nFilas): ReDim valE(1 To nFilas)

    Dim i As Long
    For i = 1 To nFilas
        valD(i) = ProcesarDerecha(CStr(datos(i, 4))) ' Columna D
        valE(i) = ProcesarDerecha(CStr(datos(i, 5))) ' Columna E
    Next i

    ' --- Diccionario para claves únicas ---
    Dim dict As Object: Set dict = CreateObject("Scripting.Dictionary")
    dict.CompareMode = vbTextCompare
    For i = 1 To nFilas
        If valD(i) <> "" Then dict(valD(i)) = 1
        If valE(i) <> "" Then dict(valE(i)) = 1
    Next i

    ' --- Pasar a array y ordenar ---
    Dim nClaves As Long: nClaves = dict.Count
    Dim claves() As String: ReDim claves(0 To nClaves - 1)
    Dim j As Long: j = 0: Dim k As Variant
    For Each k In dict.Keys: claves(j) = CStr(k): j = j + 1: Next k
    QuickSort claves, 0, nClaves - 1

    ' --- Mapear filas por clave ---
    Dim idxD() As Long, idxE() As Long
    ReDim idxD(0 To nClaves - 1): ReDim idxE(0 To nClaves - 1)

    For i = 1 To nFilas
        Dim posD As Long: posD = BuscarClave(claves, nClaves, valD(i))
        Dim posE As Long: posE = BuscarClave(claves, nClaves, valE(i))
        If posD >= 0 Then idxD(posD) = i
        If posE >= 0 Then idxE(posE) = i
    Next i

    ' --- Escribir resultado y aplicar COLORES ---
    Dim filaSalida As Long: filaSalida = 2
    Dim c As Long
    For i = 0 To nClaves - 1
        Dim fD As Long: fD = idxD(i)
        Dim fE As Long: fE = idxE(i)

        If fD > 0 And fE > 0 Then
            ' COINCIDENCIA: Copiar ambos lados
            For c = 1 To COL_LIMITE_D: wsResult.Cells(filaSalida, c).Value = datos(fD, c): Next c
            For c = COL_LIMITE_D + 1 To ultCol: wsResult.Cells(filaSalida, c).Value = datos(fE, c): Next c
        
        ElseIf fD > 0 Then
            ' SOLO EN D: Pintar columna D en ROJO (lado E queda vacío)
            For c = 1 To COL_LIMITE_D
                wsResult.Cells(filaSalida, c).Value = datos(fD, c)
                wsResult.Cells(filaSalida, c).Interior.Color = RGB(255, 200, 200) ' Rojo suave
            Next c
            
        ElseIf fE > 0 Then
            ' SOLO EN E: Pintar columna E en ROJO (lado D queda vacío)
            For c = COL_LIMITE_D + 1 To ultCol
                wsResult.Cells(filaSalida, c).Value = datos(fE, c)
                wsResult.Cells(filaSalida, c).Interior.Color = RGB(255, 200, 200) ' Rojo suave
            Next c
        End If
        
        filaSalida = filaSalida + 1
    Next i

    wsResult.Columns.AutoFit
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    MsgBox "Alineación completada. Las diferencias se han marcado en rojo.", vbInformation
End Sub

' ------------------------------------------------------------
'  Lógica de extracción: Derecha de # y reglas R / RH
' ------------------------------------------------------------
Private Function ProcesarDerecha(valor As String) As String
    Dim pos As Long
    Dim pDer As String
    
    pos = InStr(valor, "#")
    If pos > 0 Then
        pDer = UCase(Trim(Mid(valor, pos + 1)))
        
        ' Regla: RH -> 100 + el resto
        If Left(pDer, 2) = "RH" Then
            pDer = CStr(100 + Val(Mid(pDer, 3)))
        ' Regla: Omitir R inicial
        ElseIf Left(pDer, 1) = "R" Then
            pDer = Mid(pDer, 2)
        End If
        
        ' Normalizar numéricamente
        If IsNumeric(pDer) Then
            ProcesarDerecha = CStr(Val(pDer))
        Else
            ProcesarDerecha = pDer
        End If
    Else
        ProcesarDerecha = ""
    End If
End Function

' ------------------------------------------------------------
'  Funciones Auxiliares (QuickSort y Búsqueda Binaria)
' ------------------------------------------------------------
Private Sub QuickSort(arr() As String, bajo As Long, alto As Long)
    If bajo >= alto Then Exit Sub
    Dim pivote As Double: pivote = Val(arr((bajo + alto) \ 2))
    Dim i As Long: i = bajo: Dim j As Long: j = alto: Dim tmp As String
    Do
        Do While Val(arr(i)) < pivote: i = i + 1: Loop
        Do While Val(arr(j)) > pivote: j = j - 1: Loop
        If i <= j Then
            tmp = arr(i): arr(i) = arr(j): arr(j) = tmp
            i = i + 1: j = j - 1
        End If
    Loop While i <= j
    QuickSort arr, bajo, j
    QuickSort arr, i, alto
End Sub

Private Function BuscarClave(claves() As String, n As Long, clave As String) As Long
    If clave = "" Then BuscarClave = -1: Exit Function
    Dim bajo As Long: bajo = 0: Dim alto As Long: alto = n - 1
    Dim mid As Long: Dim vClave As Double: vClave = Val(clave)
    Do While bajo <= alto
        mid = (bajo + alto) \ 2
        Dim vMid As Double: vMid = Val(claves(mid))
        If vMid = vClave Then
            BuscarClave = mid: Exit Function
        ElseIf vMid < vClave Then
            bajo = mid + 1
        Else
            alto = mid - 1
        End If
    Loop
    BuscarClave = -1
End Function