/* 
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Programa:      MT250TOK.PRW
Objetivo:      Punto de entrada para validar el tipeo de datos
Diseño:        Alberto Badaui
Programación:  Alberto Badaui
Fecha inicial: 15 de Octubre del 2021
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Actualizaciones:

Fecha modificación: 
Objetivo:
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Referencias DEFINE:
--------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
USER FUNCTION MT250TOK()

LOCAL lRet := .F.

	if FWIsInCallStack("U_aptProd")
		return .T.
	endIf

IF Posicione( "SB1", 1, xFilial( "SB1" ) + M->D3_COD, "SB1->B1_VALSERI" ) = "S" .AND. (Empty( M->D3_INISERI ) .OR. Empty( M->D3_NUMSERF ))
 
   Help( Space( 1 ), 1, "SERIESISEMPTY" )

ELSEIF Posicione( "SB1", 1, xFilial( "SB1" ) + M->D3_COD, "SB1->B1_LOCALIZ" ) = "S" .AND. Empty( M->D3_UBIC )

   Help( Space( 1 ), 1, "ADRESSISEMPTY" )

ELSE

   lRet := .T.

ENDIF

RETURN lRet
