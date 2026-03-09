' ============================================================
'  AlinarColumnasCyD
'  Alinea las columnas C y D por su número (izquierda del #)
'  Crea una nueva hoja "Resultado" con las filas ordenadas y
'  alineadas: si C tiene 0257 y D tiene 0259, quedan en
'  filas separadas con la columna contraria en blanco.
' ============================================================
'
'  CONFIGURACIÓN (ajusta según tu hoja):
'    FILA_CABECERA   → fila con los títulos
'    FILA_DATOS      → primera fila con datos
'    COL_LIMITE_C    → columnas 1..COL_LIMITE_C pertenecen al
'                      "lado C" (por defecto A, B, C = 3)
'  El "lado D" son las columnas desde COL_LIMITE_C+1 en adelante.
' ============================================================

Option Explicit

Const FILA_CABECERA  As Long = 1
Const FILA_DATOS     As Long = 2
Const COL_LIMITE_C   As Long = 3   ' Columnas A-C = lado C; D en adelante = lado D

' ------------------------------------------------------------
Sub AlinarColumnasCyD()
' ------------------------------------------------------------
    Dim wsOrigen  As Worksheet
    Dim wsResult  As Worksheet
    Set wsOrigen = ActiveSheet

    Application.ScreenUpdating = False
    Application.Calculation = xlCalculationManual

    ' --- Crear / limpiar hoja de resultado ---
    Dim nombreHoja As String: nombreHoja = "Resultado"
    On Error Resume Next
    Application.DisplayAlerts = False
    Sheets(nombreHoja).Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    Set wsResult = Sheets.Add(After:=wsOrigen)
    wsResult.Name = nombreHoja

    ' --- Dimensiones del origen ---
    Dim ultFila As Long
    Dim ultCol  As Long
    ultFila = wsOrigen.Cells(wsOrigen.Rows.Count, "C").End(xlUp).Row
    ultCol  = wsOrigen.Cells(1, wsOrigen.Columns.Count).End(xlToLeft).Column

    If ultFila < FILA_DATOS Then
        MsgBox "No hay datos en la hoja.", vbExclamation
        Exit Sub
    End If

    ' --- Copiar cabecera ---
    wsOrigen.Rows(FILA_CABECERA).Copy wsResult.Rows(1)

    Dim nFilas As Long: nFilas = ultFila - FILA_DATOS + 1

    ' --- Leer todos los datos en un array ---
    Dim datos As Variant
    datos = wsOrigen.Range( _
                wsOrigen.Cells(FILA_DATOS, 1), _
                wsOrigen.Cells(ultFila, ultCol)).Value

    ' --- Extraer números de C y D ---
    Dim numC() As String
    Dim numD() As String
    ReDim numC(1 To nFilas)
    ReDim numD(1 To nFilas)

    Dim i As Long
    For i = 1 To nFilas
        numC(i) = ExtraerNum(CStr(datos(i, 3)))  ' col C = índice 3
        numD(i) = ExtraerNum(CStr(datos(i, 4)))  ' col D = índice 4
    Next i

    ' --- Recopilar números únicos en un Diccionario ---
    Dim dict As Object
    Set dict = CreateObject("Scripting.Dictionary")
    dict.CompareMode = vbTextCompare

    For i = 1 To nFilas
        If numC(i) <> "" And numC(i) <> "0" Then dict(numC(i)) = 1
        If numD(i) <> "" And numD(i) <> "0" Then dict(numD(i)) = 1
    Next i

    If dict.Count = 0 Then
        MsgBox "No se encontraron números válidos en C o D.", vbExclamation
        Exit Sub
    End If

    ' --- Pasar a array y ordenar numéricamente ---
    Dim nClaves As Long: nClaves = dict.Count
    Dim claves() As String
    ReDim claves(0 To nClaves - 1)
    Dim j As Long: j = 0
    Dim k As Variant
    For Each k In dict.Keys
        claves(j) = CStr(k)
        j = j + 1
    Next k

    OrdenarArray claves, nClaves   ' QuickSort numérico

    ' --- Para cada clave, localizar qué fila tiene ese nº en C y en D ---
    Dim idxC() As Long   ' índice en "datos" (1-based), 0 = no existe
    Dim idxD() As Long
    ReDim idxC(0 To nClaves - 1)
    ReDim idxD(0 To nClaves - 1)

    For i = 0 To nClaves - 1
        idxC(i) = 0
        idxD(i) = 0
    Next i

    For i = 1 To nFilas
        Dim posC As Long, posD As Long
        posC = BuscarClave(claves, nClaves, numC(i))
        posD = BuscarClave(claves, nClaves, numD(i))
        If posC >= 0 Then idxC(posC) = i
        If posD >= 0 Then idxD(posD) = i
    Next i

    ' --- Escribir resultado ---
    Dim filaSalida As Long: filaSalida = 2
    Dim c As Long

    For i = 0 To nClaves - 1
        Dim fC As Long: fC = idxC(i)
        Dim fD As Long: fD = idxD(i)

        If fC > 0 And fD > 0 And fC = fD Then
            '  Mismo número en C y D, misma fila → copiar toda la fila
            For c = 1 To ultCol
                wsResult.Cells(filaSalida, c).Value = datos(fC, c)
            Next c

        ElseIf fC > 0 And fD > 0 Then
            '  Mismo número pero vienen de filas distintas
            '  → lado C de la fila de C + lado D de la fila de D
            For c = 1 To COL_LIMITE_C
                wsResult.Cells(filaSalida, c).Value = datos(fC, c)
            Next c
            For c = COL_LIMITE_C + 1 To ultCol
                wsResult.Cells(filaSalida, c).Value = datos(fD, c)
            Next c

        ElseIf fC > 0 Then
            '  Solo C tiene este número → lado C relleno, lado D en blanco
            For c = 1 To COL_LIMITE_C
                wsResult.Cells(filaSalida, c).Value = datos(fC, c)
            Next c
            ' (cols D en adelante quedan vacías)

        ElseIf fD > 0 Then
            '  Solo D tiene este número → lado C en blanco, lado D relleno
            ' (cols A-C quedan vacías)
            For c = COL_LIMITE_C + 1 To ultCol
                wsResult.Cells(filaSalida, c).Value = datos(fD, c)
            Next c
        End If

        filaSalida = filaSalida + 1
    Next i

    ' --- Ajustar ancho de columnas ---
    wsResult.Columns.AutoFit

    wsResult.Activate
    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic

    MsgBox "¡Listo! Resultado en la hoja '" & nombreHoja & "'." & vbCrLf & _
           "Filas generadas: " & (filaSalida - 2), vbInformation, "AlinarColumnasCyD"
End Sub

' ------------------------------------------------------------
'  Extrae la parte izquierda del '#'; si no hay '#' devuelve el valor completo
' ------------------------------------------------------------
Private Function ExtraerNum(valor As String) As String
    Dim pos As Long
    pos = InStr(valor, "#")
    If pos > 1 Then
        ExtraerNum = Trim(Left(valor, pos - 1))
    ElseIf pos = 0 Then
        ExtraerNum = Trim(valor)
    Else
        ExtraerNum = ""
    End If
End Function

' ------------------------------------------------------------
'  QuickSort numérico sobre un array de strings
' ------------------------------------------------------------
Private Sub OrdenarArray(arr() As String, n As Long)
    QuickSort arr, 0, n - 1
End Sub

Private Sub QuickSort(arr() As String, bajo As Long, alto As Long)
    If bajo >= alto Then Exit Sub
    Dim pivote As Double: pivote = Val(arr((bajo + alto) \ 2))
    Dim i As Long: i = bajo
    Dim j As Long: j = alto
    Dim tmp As String
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

' ------------------------------------------------------------
'  Búsqueda binaria: devuelve índice en claves[] o -1 si no existe
' ------------------------------------------------------------
Private Function BuscarClave(claves() As String, n As Long, clave As String) As Long
    If clave = "" Then BuscarClave = -1: Exit Function
    Dim bajo As Long: bajo = 0
    Dim alto As Long: alto = n - 1
    Dim mid As Long
    Dim valClave As Double: valClave = Val(clave)
    Do While bajo <= alto
        mid = (bajo + alto) \ 2
        Dim valMid As Double: valMid = Val(claves(mid))
        If valMid = valClave Then
            BuscarClave = mid
            Exit Function
        ElseIf valMid < valClave Then
            bajo = mid + 1
        Else
            alto = mid - 1
        End If
    Loop
    BuscarClave = -1
End Function
