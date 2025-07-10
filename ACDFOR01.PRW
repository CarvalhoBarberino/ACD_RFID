#Include "Protheus.ch"                                                
#INCLUDE "TOPCONN.CH"

//-----------------------------------------------------------------------------------------------------------------------------
/*{Protheus.doc} ACDFOR01
MODULO IMPRESSÃO DAS ETIQUETAS DE ENDERECOS PADRAO ACD - Opção 2
@author Luiz Enrique de Araujo
@since 06/09/2023
@project  ACD FOREST
/*/  
//------------------------------------------------------------------------------------------------------------------------------
User Function ACDFOR01()

Local oFont
Local oDlgEtiEnder
Local lgerou:=.f.

Private cArmOri	:= Space(TamSX3("BE_LOCAL")[01])
Private oArmOri
Private cEndOri	:= Space(TamSX3("BE_LOCALIZ")[01])
Private oEndOri
Private cArmDes	:= Space(TamSX3("BE_LOCAL")[01])
Private oArmDes
Private cEndDes	:= Space(TamSX3("BE_LOCALIZ")[01])
Private	oEnd1Desc
Private	cEnd1Desc:= Space(TamSX3("BE_DESCRIC")[01])
Private	oEnd2Desc
Private	cEnd2Desc:= Space(TamSX3("BE_DESCRIC")[01])

Private oEndDes
Private cFila:= Space(TamSX3("CB5_CODIGO")[01]) 
Private oFila 
Private oDescEnd
Private lDescEnd:= .F.

cCadastro:= "ETIQUETAS DE ARMAZEM E ENDEREÇOS " + Dtoc(Ddatabase) + " - " + Time() 

DEFINE FONT oFont NAME "Arial" SIZE 10,15 BOLD  
DEFINE MSDIALOG oDlgEtiEnder TITLE cCadastro FROM 000,000 TO 250,900 OF oMainWnd PIXEL

@ 040, 008 SAY   "Armazem De:" 								OF	oDlgEtiEnder 	PIXEL
@ 039, 060 MSGET oArmOri	VAR cArmOri		SIZE 010, 09	OF 	oDlgEtiEnder 	PIXEL When .T.	F3 "SBE2"
@ 040, 100 SAY   "Endereço De:" 							OF 	oDlgEtiEnder 	PIXEL
@ 039, 135 MSGET oEndOri	VAR cEndOri		SIZE 060, 09   	OF 	oDlgEtiEnder 	PIXEL When .T. VALID VLDENDE(cArmOri,cEndOri,1) 
@ 039, 210 MSGET oEnd1Desc	VAR cEnd1Desc 	SIZE 090, 09   	OF 	oDlgEtiEnder 	PIXEL When .F.
  
@ 060, 008 SAY   "Armazem Até:"    							OF 	oDlgEtiEnder 	PIXEL	
@ 059, 060 MSGET oArmDes	VAR cArmDes		SIZE 010, 09   	OF 	oDlgEtiEnder 	PIXEL When .T.	F3 "SBE2"
@ 059, 100 SAY   "Endereço Até:"							OF 	oDlgEtiEnder 	PIXEL  
@ 059, 135 MSGET oEndDes	VAR cEndDes		SIZE 060, 09   	OF 	oDlgEtiEnder 	PIXEL When .T. VALID VLDENDE(cArmDes,cEndDes,2) 
@ 059, 210 MSGET oEnd2Desc	VAR cEnd2Desc 	SIZE 090, 09   	OF 	oDlgEtiEnder 	PIXEL When .F.

@ 079,008 CHECKBOX oDescEnd	VAR lDescEnd 	PROMPT "Imprimir Descritivo do Endereço" SIZE 300,7 PIXEL OF oDlgEtiEnder When .T. /*ON CLICK XXX()*/

@ 100, 008 SAY   "Local de Impressão:" OF oDlgEtiEnder PIXEL
@ 099, 060 MSGET oFila VAR cFila SIZE 50,07  OF oDlgEtiEnder PIXEL F3 'CB5' VALID LocalImp(cFila)  
*/
ACTIVATE MSDIALOG oDlgEtiEnder CENTER ON INIT EnchoiceBar(oDlgEtiEnder,{||MsgRun("Aguarde. Imprimindo...",,{|| lgerou:= PrintEti (cFila)}),If(lgerou, oDlgEtiEnder:End(),)},{||oDlgEtiEnder:End()}) //,,/*abuttons*/
//ACTIVATE DIALOG oDlgEtiEnder CENTERED	

Return

//-----------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} VLDENDE
Valida Endereco se Armazem de Inspeção é valido 
@author Luiz Enrique de Araujo
@since 02/03/2023
@version 1.0
/*/  
Static Function VLDENDE(cArmazem,cEndereco,nTipo)

Local lRet:=.T. 

If Empty(cArmazem) .or. Empty(cEndereco)
	Return
Endif 

If nTipo == 2 .And. cArmazem+cEndereco < cArmOri+cEndOri 
	ApMsgInfo("Armazem/Endereço De não pode ser Maior que Armazem/Endereço Até.","AVISO")
	Return .f.
Endif
  
SBE->(DbSetOrder(1))
If !SBE->(DbSeek(xFilial("SBE")+cArmazem+cEndereco))
	If nTipo == 1
		ApMsgInfo("Armazem ou Endereço De, Invalido.","AVISO")
	Else
		ApMsgInfo("Armazem ou Endereço Até, Invalido.","AVISO")
	Endif		
	lRet:=.F.  
Else
	If nTipo == 1
		cEnd1Desc:= Alltrim(SBE->BE_DESCRIC)
		oEnd1Desc:Refresh()
	Else
		cEnd2Desc:= Alltrim(SBE->BE_DESCRIC)
		oEnd2Desc:Refresh()
	Endif
EndIf

Return lRet 

//-----------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} PrintEti
Impressao da etiqueta de Endereco 
@author Luiz Enrique de Araujo
@since 02/03/2023
@version 1.0
/*/  
Static Function PrintEti (cLocImp) 
Local cQuery := ""

If Empty(cLocImp) 
	MsgAlert("Declare o Local de Impressão.","Atenção")
	Return .t.
EndIf

cQuery := " SELECT * FROM "+RetSqlName("SBE")	+" "
cQuery += " WHERE BE_LOCAL >= '"	+cArmOri	+"' " 
cQuery += " AND BE_LOCALIZ >= '"	+cEndOri	+"' "
cQuery += " AND BE_LOCAL <= '"		+cArmDes	+"' "
cQuery += " AND BE_LOCALIZ <= '"	+cEndDes	+"' "
cQuery += " AND BE_FILIAL = '"		+xFilial("SBE")+"' "
cQuery += " AND D_E_L_E_T_ <> '*' "
cQuery += " ORDER BY BE_LOCAL,BE_LOCALIZ " 
cQuery := ChangeQuery(cQuery)		
TCQUERY cQuery NEW ALIAS "CETIQ" 

If CETIQ->(! Eof())	
	If !MsgYesNo("Confirma impressão da etiqueta?",":: Atenção ::") 
		CETIQ->(DbCloseArea())
		Return .t.
	Endif
	
	CB5SetImp(cLocImp,.F.)
	SBE->(dbsetOrder(1))
	While  CETIQ->(! Eof())	       	
		If SBE->(DbSeek(xFilial("SBE")+CETIQ->BE_LOCAL+CETIQ->BE_LOCALIZ))
	   		ExecBlock("IMG02",.f.,,{lDescEnd})
		Endif 
		sleep(100)	
		CETIQ->(DbSkip())
	EndDo
	MSCBCLOSEPRINTER() 
	MsgAlert("Impressão Finalizada.","Atenção")
Else
	MsgAlert("Não ha Dados para Impressão.","Atenção")
Endif

CETIQ->(DbCloseArea())
	
Return .t.

//-----------------------------------------------------------------------------------------------------------------------------
/*/{Protheus.doc} LocalImp
Verifica se local de impressão é valido
@author Luiz Enrique de Araujo
@since 02/03/2023
@version 1.0
/*/  
Static Function LocalImp (CodLocal)
 	     
CB5->(dbsetOrder(1))
If !CB5->(dbSeek(xFilial()+CodLocal)) 
	CBAlert("Local de Impressão Inválido")
	Return .F.
Endif  
  
Return .T.   
