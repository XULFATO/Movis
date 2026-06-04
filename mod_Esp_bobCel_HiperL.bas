Attribute VB_Name = "mod_Esp_bobCel_HiperL"
Sub CrearHipervinculoCoincidencia(worksheetact As Workbook)
    Dim wsOrigen As Worksheet
    Dim wsDestino As Worksheet
    Dim celdaBusqueda As Range
    Dim textoBuscar As String
    Dim filaEncontrada As Long
    Dim rutaDestino As String
    
    ' 1. CONFIGURACIÓN: Ajusta los nombres de tus hojas y celdas
    Set wsOrigen = worksheetact.Sheets("Preg Generales - Propuesta 2")  ' Hoja donde se crea el hipervínculo
    Set wsDestino = worksheetact.Sheets("Preg Generales - Propuesta 2") ' Hoja donde están los datos
    
   ' MsgBox worksheetact.Name
    
        Call DesprotegerHoja(wsOrigen)
    
    
     For i = 9 To 20
    Set celdaBusqueda = wsOrigen.Range(wsOrigen.Cells(i, 2), wsOrigen.Cells(i, 2))   ' Celda donde pondrás el enlace
    textoBuscar = wsOrigen.Cells(i, 2).Value  ' PARTE DEL LITERAL para buscas
    
    ' 2. BÚSQUEDA: Buscar en la Columna A de la hoja de destino (coincidencia parcial)
    On Error Resume Next
    filaEncontrada = wsDestino.Columns("A").Find(What:="*" & textoBuscar & "*", _
                     LookAt:=xlPart, SearchOrder:=xlByRows).Row
    On Error GoTo 0
    
    ' 3. COMPROBACIÓN: Verificar si se encontró la fila
    If filaEncontrada > 0 Then
        ' Construye la referencia de la celda (por ejemplo: Hoja2!A14)
        rutaDestino = "'" & wsDestino.Name & "'!A" & filaEncontrada
        
        ' Crea el hipervínculo en la celda designada
        wsOrigen.Hyperlinks.Add Anchor:=celdaBusqueda, _
                                Address:="", _
                                SubAddress:=rutaDestino, _
                                TextToDisplay:=textoBuscar
                                
       ' MsgBox "¡Hipervínculo creado con éxito en la fila " & filaEncontrada & "!", vbInformation
   ' Else
   '
   ' MsgBox "No se encontraron coincidencias con '" & textoBuscar & "'", vbExclamation
    End If
    
    Next i
    
    
          Call ProtegerHoja(wsOrigen)
    
End Sub



