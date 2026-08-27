#INCLUDE 'PROTHEUS.CH'
#INCLUDE "TOTVS.CH"

STATIC nSeriesLen := GetMV( "SU_SERLEN" )

/* 
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Programa:      A250ETRAN.PRW
Objetivo:      Punto de entrada para grabar la ubicación de producto y trazabilidad
Diseño:        Alberto Badaui
Programación:  Alberto Badaui
Fecha inicial: 12 de Octubre del 2021
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Actualizaciones:

Fecha modificación: 
Objetivo:
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Referencias DEFINE:
--------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
USER FUNCTION A250ETRAN()

LOCAL aSB1Area           := SB1->( GetArea() ),;
      aSB2Area           := SB2->( GetArea() ),;
      aSB8Area           := SB8->( GetArea() ),;      
      aSDAArea           := SDA->( GetArea() ),;      
      aSBFArea           := SBF->( GetArea() ),;      
      i,;
      cSeries,;
      lError             := .F.,;
      nItem              := 0,;
      cNOper,;
      aSourceTransaction := { "A250ETRAN"                                                    /* ZA2->ZA2_SOURCE */,;
                              cEmpAnt                                                        /* ZA2->ZA2_COMPAN */  ,;
                              cFilAnt                                                        /* ZA2->ZA2_BRANCH */,;
                              dDataBase                                                      /* ZA2->ZA2_DATE */,;
                              Left( Time(), 2) + SubStr( Time(), 4, 2 ) + Right( Time(), 2 ) /* ZA2->ZA2_TIME */,;
                              Space( 0 )                                                     /* ZA2->ZA2_OPERAT */,;
                              Space( 0 )                                                     /* ZA2->ZA2_DOC */,;
                              Space( 0 )                                                     /* ZA2->ZA2_SERIES */,;
                              CToD( Space( 0 ) )                                             /* ZA2->ZA2_DATED */;
                            },;
      cTransactionId   

	if FWIsInCallStack("U_aptProd")
		return nil
	endIf

cTransactionId := aSourceTransaction[1] + aSourceTransaction[2] + aSourceTransaction[3] + DToS( aSourceTransaction[4] ) + aSourceTransaction[5]

/* Inicio del servicio */	
U_GenerateEvent( "startofservice", "Seguimiento de Cierre de Producción - Transaccion: " + cTransactionId + ", desde " + aSourceTransaction[1] + " del: " + DToC( dDataBase ) +;
                 ", hora: " + Time(),,, .F.,, aSourceTransaction, .F. )                  

/* Seteo del índice a utilizar */
SB1->( DBSetOrder( 1 ) )
SB2->( DBSetOrder( 1 ) )
SB8->( DBSetOrder( 3 ) )
SDA->( DbSetOrder( 1 ) )
SBF->( DBSetOrder( 1 ) )

/* Identificar el registro SD3 correspondiente al producto terminado */
FOR i := 1 TO Len( aAtuSD3 )

   SD3->( DBGoTo( aAtuSD3[i] ) )

   IF SB1->( DBSeek( xFilial( "SB1" ) + SD3->D3_COD ) ) .AND. SB1->B1_TIPO $ "PT|PA" .AND. SD3->D3_ESTORNO != "S"

      EXIT

   ENDIF

NEXT

/* Identificar el registro SD3 correspondiente al producto semielaborado */
IF i > Len( aAtuSD3 )

   FOR i := 1 TO Len( aAtuSD3 )

      SD3->( DBGoTo( aAtuSD3[i] ) )

      IF SB1->( DBSeek( xFilial( "SB1" ) + SD3->D3_COD ) ) .AND. SB1->B1_TIPO $ "SE|PI" .AND. SD3->D3_ESTORNO != "S"

         EXIT

      ENDIF

   NEXT

ENDIF

/* Procesamiento de la Trazabilidad y Distribución */
IF i <= Len( aAtuSD3 )

   aSourceTransaction[6] := SD3->D3_TM
   aSourceTransaction[7] := SD3->D3_DOC
   aSourceTransaction[9] := SD3->D3_EMISSAO

   IF SD3->D3_TM != "002"

      U_GenerateEvent( , "Error en SD3.  La columna D3_TM contiene: " + SD3->D3_TM,,,,,, aSourceTransaction, .F. )
      U_GenerateEvent( , "Registro en SD3: " + AllTrim( Str( aAtuSD3[i] ) ),,,,,, aSourceTransaction, .F. )
      U_GenerateEvent( , "IP Solicitante: " + GetClientIp() + ", Terminal: " +  GetComputerName(),,,,,, aSourceTransaction, .F. )

   ENDIF

   IF SB2->( DBSeek( SD3->D3_FILIAL + SD3->D3_COD + SD3->D3_LOCAL ) )

      RecLock( "SB2", .F. )

      SB2->B2_QACLASS -= SD3->D3_QUANT

      MSUnLock()

   ELSE

      U_GenerateEvent( , "INTERNALERRORONSB2 - No se encontró el Stock del Producto: " + SD3->D3_COD + " para el Depósito: " + SD3->D3_LOCAL,,,,,, aSourceTransaction, .F. )

      Help( Space( 1 ), 1, "INTERNALERRORONSB2" )

      lError := .T.

   ENDIF

   IF !lError .AND. SB1->B1_RASTRO $ "L|S" .AND. SB8->( DBSeek( SD3->D3_FILIAL + SD3->D3_COD + SD3->D3_LOCAL + SD3->D3_LOTECTL ) )

      RecLock( "SB8", .F. )

      SB8->B8_QACLASS -= SD3->D3_QUANT

      MSUnLock()

   ELSE

      U_GenerateEvent( , "INTERNALERRORONSB8 - No se encontró el Stock del Producto: " + SD3->D3_COD + " para el Depósito: " + SD3->D3_LOCAL + " del Lote: " + SD3->D3_LOTECTL,;
                       ,,,,, aSourceTransaction, .F. )

      Help( Space( 1 ), 1, "INTERNALERRORONSB8" )

      lError := .T.

   ENDIF

   /* Grabación de la TRAZABILIDAD y UBICACION FISICA */
   IF !lError .AND. (SB1->B1_LOCALIZ = "S" .OR. SB1->B1_VALSERI = "S")

      cSeries := SD3->D3_INISERI

      WHILE cSeries <= SD3->D3_NUMSERF .AND. SB1->B1_VALSERI = "S"

         RecLock( "SBF", .T. )

         SBF->BF_FILIAL  := SD3->D3_FILIAL
         SBF->BF_PRODUTO := SD3->D3_COD
         SBF->BF_LOCAL   := SD3->D3_LOCAL
         SBF->BF_PRIOR   := "ZZZ"
         SBF->BF_LOCALIZ := SD3->D3_UBIC
         SBF->BF_NUMSERI := cSeries
         SBF->BF_LOTECTL := SD3->D3_LOTECTL
         SBF->BF_QUANT   := 1

         MSUnLock()

         cNOper  := GetSx8Num( "SDB", "DB_IDOPERA" ); ConfirmSX8()

         RecLock( "SDB", .T. )

         SDB->DB_FILIAL  := SD3->D3_FILIAL
         SDB->DB_ITEM    := StrZero( ++nItem, 4 )
         SDB->DB_NUMSERI := cSeries
         SDB->DB_PRODUTO := SD3->D3_COD
         SDB->DB_LOCAL   := SD3->D3_LOCAL
         SDB->DB_LOCALIZ := SD3->D3_UBIC
         SDB->DB_DOC     := SD3->D3_DOC
         SDB->DB_TM      := SD3->D3_TM
         SDB->DB_ORIGEM  := "SD3"
         SDB->DB_QUANT   := 1
         SDB->DB_DATA    := SD3->D3_EMISSAO
         SDB->DB_LOTECTL := SD3->D3_LOTECTL
         SDB->DB_NUMSEQ  := SD3->D3_NUMSEQ
         SDB->DB_TIPO    := "D"
         SDB->DB_SERVIC  := "499"
         SDB->DB_ATIVID  := "ZZZ"
         SDB->DB_HRINI   := Left( Time(), 5 )
         SDB->DB_ATUEST  := "S"
         SDB->DB_ORDATIV := "ZZ"
         SDB->DB_IDOPERA := cNOper

         MSUnLock()

         cSeries := Left( cSeries, (U_FindSeriesNumber( cSeries ) - 1) ) + StrZero( (Val( SubStr( cSeries, U_FindSeriesNumber( cSeries ) ) ) + 1), nSeriesLen )

      ENDDO

      /* Registrar la TRAZABILIDAD */
      IF SDA->( DBSeek( SD3->D3_FILIAL + SD3->D3_COD + SD3->D3_LOCAL + SD3->D3_NUMSEQ + SD3->D3_DOC ) )

         RecLock( "SDA", .F. )

         SDA->DA_SALDO := 0

         MSUnLock()

      ELSEIF SB1->B1_VALSERI = "S"

         U_GenerateEvent( , "INTERNALERRORONSDA  - No se encontró la Trazabilidad del Producto: " + SD3->D3_COD + " para el Depósito: " + SD3->D3_LOCAL +;
                            " de la Secuencia: " + SD3->D3_NUMSEQ,,,,,, aSourceTransaction, .F. )

         Help( Space( 1 ), 1, "INTERNALERRORONSDA" )

         lError := .T.

      ENDIF

      /* Registra la DISTRIBUCION si el producto NO tiene control de TRAZABILIDAD */
      IF !lError .AND. SB1->B1_LOCALIZ = "S" .AND. SB1->B1_VALSERI != "S"

         IF !SBF->( DBSeek( SD3->D3_FILIAL + SD3->D3_LOCAL + SD3->D3_UBIC + SD3->D3_COD + SD3->D3_NUMSERI + SD3->D3_LOTECTL ) )

            RecLock( "SBF", .T. )

            SBF->BF_FILIAL  := SD3->D3_FILIAL
            SBF->BF_PRODUTO := SD3->D3_COD
            SBF->BF_LOCAL   := SD3->D3_LOCAL
            SBF->BF_PRIOR   := "ZZZ"
            SBF->BF_LOCALIZ := SD3->D3_UBIC
            SBF->BF_LOTECTL := SD3->D3_LOTECTL

         ELSE

            RecLock( "SBF", .F. )

         ENDIF

         SBF->BF_QUANT += SD3->D3_QUANT

         MSUnLock()

         cNOper := GetSx8Num( "SDB", "DB_IDOPERA" ); ConfirmSX8()

         RecLock( "SDB", .T. )

         SDB->DB_FILIAL  := SD3->D3_FILIAL
         SDB->DB_ITEM    := StrZero( 1, 4 )
         SDB->DB_PRODUTO := SD3->D3_COD
         SDB->DB_LOCAL   := SD3->D3_LOCAL
         SDB->DB_LOCALIZ := SD3->D3_UBIC
         SDB->DB_DOC     := SD3->D3_DOC
         SDB->DB_TM      := SD3->D3_TM
         SDB->DB_ORIGEM  := "SD3"
         SDB->DB_QUANT   := SD3->D3_QUANT
         SDB->DB_DATA    := SD3->D3_EMISSAO
         SDB->DB_LOTECTL := SD3->D3_LOTECTL
         SDB->DB_NUMSEQ  := SD3->D3_NUMSEQ
         SDB->DB_TIPO    := "D"
         SDB->DB_SERVIC  := "499"
         SDB->DB_ATIVID  := "ZZZ"
         SDB->DB_HRINI   := Left( Time(), 5 )
         SDB->DB_ATUEST  := "S"
         SDB->DB_ORDATIV := "ZZ"
         SDB->DB_IDOPERA := cNOper

         MSUnLock()

      ENDIF

   ENDIF

ELSE

   U_GenerateEvent( , "INTERNALERRORONE25  - No se encontró el Movimiento Interno de Cierre",,,,, aSourceTransaction, .F. )

   Help( Space( 1 ), 1, "INTERNALERRORONE25" )

   lError := .T.

ENDIF

/* Inicialización del array que contiene los registros SD3 a ser procesados */
aAtuSD3 := Array( 0 )

/* Restauración de areas activas */
RestArea( aSB1Area )
RestArea( aSB2Area )
RestArea( aSB8Area )
RestArea( aSDAArea )
RestArea( aSBFArea )

/* Fin del servicio */	
U_GenerateEvent( "endofservice", "Seguimiento de Cierre de Producción - Transaccion: " + cTransactionId + ", desde " + aSourceTransaction[1] + " del: " + DToC( dDataBase ) +;
                 ", hora: " + Time(),,, .F.,, aSourceTransaction, .F. )
                 
RETURN NIL
