Sub CompararColumnasConFormatoNumeroHash()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim valorE As String, valorG As String
    Dim partesE() As String, partesG() As String
    Dim izquierdaE As String, derechaE As String
    Dim izquierdaG As String, derechaG As String
    Dim resultado As String
    
    ' Establecer la hoja activa
    Set ws = ActiveSheet
    
    ' Encontrar la última fila con datos en columna E o G
    lastRow = Application.WorksheetFunction.Max(ws.Cells(ws.Rows.Count, "E").End(xlUp).Row, _
                                                ws.Cells(ws.Rows.Count, "G").End(xlUp).Row)
    
    ' Limpiar columna I antes de empezar
    ws.Range("I1:I" & lastRow).ClearContents
    
    ' Encabezado
    ws.Range("I1").Value = "Resultado Comparación"
    
    ' Recorrer filas
    For i = 2 To lastRow
        valorE = Trim(CStr(ws.Cells(i, "E").Value))
        valorG = Trim(CStr(ws.Cells(i, "G").Value))
        
        ' Inicializar variables
        izquierdaE = ""
        derechaE = ""
        izquierdaG = ""
        derechaG = ""
        
        ' Procesar valor de columna E
        If InStr(valorE, "#") > 0 Then
            partesE = Split(valorE, "#")
            izquierdaE = Trim(partesE(0))
            If UBound(partesE) >= 1 Then
                derechaE = Trim(partesE(1))
            End If
        Else
            izquierdaE = valorE
        End If
        
        ' Procesar valor de columna G
        If InStr(valorG, "#") > 0 Then
            partesG = Split(valorG, "#")
            izquierdaG = Trim(partesG(0))
            If UBound(partesG) >= 1 Then
                derechaG = Trim(partesG(1))
            End If
        Else
            izquierdaG = valorG
        End If
        
        ' Comparar
        If izquierdaE = "" And izquierdaG = "" Then
            resultado = "Ambas vacías"
        ElseIf izquierdaE = "" Or izquierdaG = "" Then
            resultado = "Falta valor en una columna"
        ElseIf izquierdaE <> izquierdaG Then
            resultado = "Parte izquierda diferente"
        Else
            ' Partes izquierdas coinciden, comparar derechas
            If derechaE = "" And derechaG = "" Then
                resultado = "Coinciden completamente"
            ElseIf derechaE = "" Or derechaG = "" Then
                resultado = "Parte derecha falta en una columna"
            ElseIf derechaE = derechaG Then
                resultado = "Coinciden completamente"
            Else
                resultado = "Parte derecha diferente"
            End If
        End If
        
        ' Escribir resultado en columna I
        ws.Cells(i, "I").Value = resultado
    Next i
    
    ' Ajustar ancho de columna
    ws.Columns("I").AutoFit
    
    MsgBox "Comparación completada. Se procesaron " & (lastRow - 1) & " filas.", vbInformation
End Sub
