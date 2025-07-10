#INCLUDE "ACDI011.ch"
#Include "Protheus.ch"
#Include "ApWizard.ch"


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ACDI011  ³ Autor ³      TOTVS S/A        ³ Data ³ 01/01/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Realizar a impressao das etiquetas termicas de ident		  ³±±
±±³			 ³ de produto no padrão codigo natural/EAN conforme as opcoes ³±±
±±³			 ³ disponives a seguir.                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ACDI011(nOrigem,aParIni)                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function UACDI011(nOrigem,aParIni)

	LOCAL oWizard
	LOCAL oPanel
	LOCAL nTam
	LOCAL nTamDoc:= TamSX3("F1_DOC")[1]
	LOCAL nSerie := TAmSX3("F1_SERIE")[1]
	LOCAL nCodigo:= TamSX3("A2_COD")[1]
	LOCAL nLoja  := TamSX3("A2_LOJA")[1]
	LOCAL lRun 	 := .F.
	LOCAL oOrigem
	LOCAL aOrigem	:= {}

	LOCAL aparNF	:= {	{1,STR0001 		,nTamDoc ,"","","CBW"	,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Nota Fiscal"
	{1,STR0002 		,nSerie  ,"","",		,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Serie"
	{1,STR0003		,nCodigo ,"","","SA2"	,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Fornecedor"
	{1,STR0004		,nLoja   ,"","",		,If(aParIni==NIL,".T.",".F."),0,.F.} } //"Loja"

	LOCAL aRetNF	:= {Space(nTamDoc),Space(nSerie),Space(nCodigo),Space(nLoja)}

	LOCAL aParPR	:= {{1,"Do Produto" ,Space(Tamsx3("B1_COD")[1]),"","","SB1",If(aParIni==NIL,".T.",".F."),115,.F.},;
		{1,"Ate Produto",Space(Tamsx3("B1_COD")[1]),"","","SB1",If(aParIni==NIL,".T.",".F."),115,.F.}} //"Produto"

	LOCAL aRetPR	:= {Space(Tamsx3("B1_COD")[1]),Space(Tamsx3("B1_COD")[1])}

	LOCAL aParOP	:= {{1, STR0007 ,Space(13),"","","SC2"	,If(aParIni==NIL,".T.",".F."),60,.F.}}
	LOCAL aRetOP	:= {Space(13)}
	LOCAL aParImp	:= {{1, STR0006	,Space(06),"","","CB5"	,".T.",0,.F.}} //"LOCAL de Impressão"
	LOCAL aRetImp	:= {Space(6)}

	LOCAL cCodPt	:= CriaVar( "CB0_PALLET", .F. )
	LOCAL aParam	:= {}
	LOCAL aRetPE	:= {}

	LOCAL nx:= 1

	PRIVATE cAlmDe  := Space(TamSX3("BE_LOCAL")[1])
	PRIVATE cAlmAte := Space(TamSX3("BE_LOCAL")[1])
	PRIVATE cEndDe  := Space(TamSX3("BE_LOCALIZ")[1])
	PRIVATE cEndAte := Space(TamSX3("BE_LOCALIZ")[1])

	PRIVATE aParAv	:= {{1,"Do Almoxarifado" ,cAlmDe ,"","","NNR",If(aParIni==NIL,".T.",".F."), 0,.F.},;
		{1,"Ate Almoxarifado",cAlmAte,"","","NNR",If(aParIni==NIL,".T.",".F."), 0,.F.},;
		{1,"Do Endereco"	 ,cEndDe ,"","","SBE",If(aParIni==NIL,".T.",".F."),40,.F.},;
		{1,"Ate Endereco"	 ,cEndAte,"","","SBE",If(aParIni==NIL,".T.",".F."),40,.F.} }

	PRIVATE aRetAv	:= {cAlmDe,cAlmAte,cEndDe,cEndAte}

	PRIVATE nTamArm   := TamSX3("B2_LOCAL")[1]
	PRIVATE nTamLote  := TamSX3("B8_LOTECTL")[1]
	PRIVATE nTamSLote := TamSX3("B8_NUMLOTE")[1]
	PRIVATE nTamSerie := TamSX3("BF_NUMSERI")[1]
	PRIVATE nTamEnder := Tamsx3("BE_LOCALIZ")[1]

	PRIVATE cCondSF1:= ' 1234567890'  // variavel utilizada na consulta sxb CBW, favor nao remover esta linha
	PRIVATE oLbx
	PRIVATE aLbx	:= {{.f.,;
		Space(Tamsx3("B1_COD")[1]),;
		Space(Tamsx3("B1_DESC")[1]),;
		Space(10),;
		Space(10),;
		Space(nTamArm),;
		Space(nTamLote),;
		Space(nTamEnder),;
		Space(Tamsx3("C5_NUM")[1]),;
		Space(3),;
		0}}
	PRIVATE aSvPar	:= {}
	PRIVATE cOpcSel	:= ""  // variavel disponivel para infomar a opcao de origem selecionada
	PRIVATE cOriPalLang := ""
	PRIVATE aTitle := {" ",;
		"Produto",;
		"Descrição",;
		"Qtd.",;
		"Cópias",;
		"Armazem",;
		"Lote",;
		"Endereço",;
		"Pedido/ID Bobina",;
		"Origem",;
		"Id"} as Array
	PRIVATE _lCopia := .F.

	DEFAULT nOrigem := 1

	aParam := { {STR0001	      ,aParNF,aRetNF,{|| AWzVNF() } },; //"Nota Fiscal"
	{"Produto Avulso" ,aParPR,aRetPR,{|| AWzVPR() } },; //"Produto Avulso"
	{STR0007	      ,aParOP,aRetOP,{|| AWzVOP() } },; //"Ordem de Producao"
	{"Ident. de Endereço Físico" ,aParAv,aRetAv,{|| AWzVAv() } }} //Ident. de Endereço Físico

	If ExistBlock("ACDI11PA")

		aRetPE := ExecBlock("ACDI11PA",.F.,.F.,{aParam})
		If ValType(aRetPE) == "A"
			aParam := aClone(aRetPE)
		EndIf

	EndIf

// carrega parametros vindo da funcao pai
	If aParIni <> NIL
		For nX := 1 to len(aParIni)
			nTam := len( aParam[nOrigem,3,nX ] )
			aParam[nOrigem,3,nX ] := Padr(aParIni[nX],nTam )
		Next
	EndIf

	For nx:= 1 to len(aParam)
		aadd(aOrigem,aParam[nX,1])
	Next

	ChkParm()

	DEFINE WIZARD oWizard TITLE STR0008 ; //"Etiqueta de Produto ACD"
	HEADER STR0009 ; //"Rotina de Impress? de etiquetas termica."
	MESSAGE "";
		TEXT STR0010 ; //"Esta rotina tem por objetivo realizar a impressao das etiquetas termicas de identifica?o de produto no padr? codigo natural/EAN conforme as opcoes disponives a seguir."
NEXT {|| .T.} ;
	FINISH {|| .T. } ;
	PANEL

// Primeira etapa
CREATE PANEL oWizard ;
	HEADER STR0011 ; //"Informe a origem das informa?es para impress?"
MESSAGE "" ;
	BACK {|| .T. } ;
	NEXT {|| nc:= 0,aeval(aParam,{|| &("oP"+str(++nc,1)):Hide()} ),&("oP"+str(nOrigem,1)+":Show()"),cOpcSel:= aParam[nOrigem,1],A11WZIniPar(nOrigem,aParIni,aParam) ,.T. } ;
	FINISH {|| .F. } ;
	PANEL

oPanel := oWizard:GetPanel(2)

oOrigem := TRadMenu():New(30,10,aOrigem,BSetGet(nOrigem),oPanel,,,,,,,,100,8,,,,.T.)

If aParIni <> NIL
	oOrigem:Disable()
EndIf

// Segunda etapa
CREATE PANEL oWizard ;
	HEADER STR0012 ; //"Preencha as solicita?es abaixo para a sele?o do produto"
MESSAGE "" ;
	BACK {|| .T. } ;
	NEXT {|| lRun := Eval( aParam[nOrigem,4] ), IIf( lRun, IIf( nOrigem == 4, ( oWizard:GetPanel(4):Hide(),oWizard:SetPanel( 5 ), oWizard:GetPanel(5):Show() ), .T. ) , lRun )  } ; //WzVldAct( oWizard, oPanel, aParam, nOrigem )
FINISH {|| .F. } ;
	PANEL

oPanel := oWizard:GetPanel(3)

For nx:= 1 to len(aParam)
	&("oP"+str(nx,1)) := TPanel():New( 028, 072, ,oPanel, , , , , , 120, 20, .F.,.T. )
	&("oP"+str(nx,1)):align:= CONTROL_ALIGN_ALLCLIENT

	Do Case
	Case nx == 1

		ParamBox(aParNF,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Par?etros..."

	Case nx == 2

		ParamBox(aParPR,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Par?etros..."

	Case nx == 3

		ParamBox(aParOP,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Par?etros..."

	Case nx == 4

		ParamBox(aParAv,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Par?metros..."

	EndCase

	&("oP"+str(nx,1)):Hide()
Next

CREATE PANEL oWizard ;
	HEADER STR0014 ; //"Parametriza?o por produto"
MESSAGE STR0015 ; //"Marque os produtos que deseja imprimir"
BACK {|| .T. } ;
	NEXT {|| aRetImp  := {Space(6)},VldaLbx()} ;
	FINISH {|| .T. } ;
	PANEL
oPanel := oWizard:GetPanel(4)

ListBoxMar(oPanel)

CREATE PANEL oWizard ;
	HEADER STR0016 ; //"Parametriza?o da impressora"
MESSAGE STR0017 ; //"Informe o LOCAL de Impress?"
BACK {||  IIf( nOrigem == 4, ( oWizard:GetPanel(4):Hide(), oWizard:SetPanel( 3 ), oWizard:GetPanel(3):Show() ), .T. )  } ;
	NEXT {|| Imprime( aParam[nOrigem,1], cCodPt, aRetImp, nOrigem ) } ;
	FINISH {|| .T.  } ;
	PANEL
oPanel := oWizard:GetPanel(5)
ParamBox(aParImp,STR0013,aRetImp,,,,,,oPanel)	 //"Par?etros..."

CREATE PANEL oWizard ;
	HEADER STR0018 ; //"Impress? Finalizada"
MESSAGE "" ;
	BACK {|| .T. } ;
	NEXT {|| .T. } ;
	FINISH {|| .T.  } ;
	PANEL

ACTIVATE WIZARD oWizard CENTERED

Return

Static Function A11WZIniPar(nOrigem, aParIni,aParam)
	LOCAL nX
	If aParIni <> NIL
		For nx:= 1 to len(aParIni)
			&( "MV_PAR" + StrZero( nX, 2, 0 ) ) := aParIni[ nX ]
		Next
	EndIf

	For nx:= 1 to len(aParam[nOrigem,3])
		&( "MV_PAR" + StrZero( nX, 2, 0 ) ) := aParam[nOrigem,3,nX ]
	Next

Return .t.

Static Function AWzVNF()
	LOCAL cNota := Padr(MV_PAR01,TamSx3("F1_DOC")[1])
	LOCAL cForn := Padr(MV_PAR03,TamSx3("A2_COD")[1])
	LOCAL cLoja := Padr(MV_PAR04,TamSx3("A2_LOJA")[1])
	LOCAL cSerie:= ConsSerNf("SF1", MV_PAR02, cNota, cForn, cLoja )//Padr(MV_PAR02,3)
	LOCAL oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
	LOCAL oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL nT	:= TamSx3("D3_QUANT")[1]
	LOCAL nD	:= TamSx3("D3_QUANT")[2]

	If Empty(cNota+cSerie+cForn+cLoja)
		MsgAlert(STR0019) //" Necessario informar a nota e o fornecedor. "
		Return .F.
	EndIf

	SF1->(DbSetOrder(1))
	If !SF1->(DbSeek(xFilial('SF1')+cNota+cSerie+cForn+cLoja))
		MsgAlert(STR0020) //" Nota fiscal não encontrada. "
		Return .F.
	EndIf

	_lCopia := .T.
	aLbx    :={}

	SD1->(DbSetOrder(1))
	SD1->(dbSeek(xFilial('SD1')+cNota+cSerie+cForn+cLoja)	)
	While SD1->(!EOF()  .and. D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA == xFilial('SD1')+cNota+cSerie+cForn+cLoja)

		SB1->(dbSeek(xFilial('SB1')+SD1->D1_COD))

		If ! CBImpEti(SB1->B1_COD)
			SD1->(dbSkip())
			Loop
		EndIf
		nQE     := CBQEmbI()
		nQE	    := If(Empty(nQE),1,nQE)

		SB1->( MSSeek( FWxFilial("SB1") + SD1->D1_COD, .F.) )

		aAdd(aLbx,{.f.,SD1->D1_COD, SB1->B1_DESC, Str(SD1->D1_QUANT,nT,nD),Str(nQE,nT,nD),SD1->D1_LOCAL,SD1->D1_LOTECTL," "," ","SD1",SD1->(Recno())})
		SD1->(dbSkip()	)

	End

	oLbx:SetArray( aLbx )
	oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
	oLbx:Refresh()

Return .t.

Static Function AWzVPR()
	LOCAL cProduto	:= Padr(MV_PAR01,Tamsx3("B1_COD")[1])
	LOCAL cProdAte	:= Padr(MV_PAR02,Tamsx3("B1_COD")[1])
	LOCAL oOk		:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
	LOCAL oNo		:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL nT		:= TamSx3("D3_QUANT")[1]
	LOCAL nD		:= TamSx3("D3_QUANT")[2]
	LOCAL nQtdEti	:= 0
	LOCAL _nIdxSBF   := SBF->( IndexOrd() )

	If Empty(cProduto)
		MsgAlert(STR0021) //" Necessario informar o codigo do produto. "
		Return .F.
	EndIf

	SB1->(DbSetOrder(1))
	If ! SB1->(DbSeek(xFilial('SB1')+cProduto))
		MsgAlert(STR0022) //" Produto não encontrado "
		Return .F.
	EndIf

	If ! CBImpEti(SB1->B1_COD)
		MsgAlert(STR0023) //" Este Produto está configurado para nao imprimir etiqueta "
		Return .F.
	EndIf

	nQtdEti := IIf( Empty( CBQEmbI() ), 0, CBQEmbI() )

	cFiltro := "@ (BF_FILIAL = '"+ FWxFilial("SBF") +"') AND (BF_PRODUTO BETWEEN '"+ cProduto +"' AND '"+cProdAte+"') AND (BF_QUANT <> 0) AND (R_E_C_D_E_L_ = 0)"
	SBF->( dbSetFilter( {|| &cFiltro }, cFiltro ))
	SBF->( dbSetOrder( 2 ) ) /* Produto + Estrutura Fisica + Endereço */
	SBF->(  dbGoTop() )

	If ! SBF->( Eof() )

		aLbx := {}

	End

	While ! SBF->( Eof() )

		SB1->( MSSeek( xFilial("SB1")+SBF->BF_PRODUTO, .F.))
		aAdd(aLbx,{.f.,SB1->B1_COD, SB1->B1_DESC, Str(SBF->BF_QUANT,nT,nD),Str(nQtdEti,nT,nD),SBF->BF_LOCAL,SBF->BF_LOTECTL,SBF->BF_LOCALIZ," ","SBF",SBF->(Recno())})
		SBF->( dbSkip() )

	End

	oLbx:SetArray( aLbx )
	oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
	oLbx:Refresh()

	SBF->( dbClearFilter() )
	SBF->( dbSetOrder( _nIdxSBF ) )

Return .t.

Static Function AWzVOP()
	LOCAL cOp	:= Padr(MV_PAR01,13)
	LOCAL oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
	LOCAL oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL nQtde
	LOCAL nQE
	LOCAL nQVol
	LOCAL nResto
	LOCAL nT	:= TamSx3("D3_QUANT")[1]
	LOCAL nD	:= TamSx3("D3_QUANT")[2]

	If Empty(cOP)
		MsgAlert(STR0024) //" Necessario informar o codigo do ordem de produção. "
		Return .F.
	EndIf

	SC2->(DbSetOrder(1))
	If ! SC2->(DbSeek(xFilial('SC2')+cOP))
		MsgAlert(STR0025) //" Ordem de Produção não encontrado "
		Return .F.
	EndIf

	SB1->(DbSetOrder(1))
	SB1->(DbSeek(xFilial("SB1")+SC2->C2_PRODUTO))
	If ! CBImpEti(SB1->B1_COD)
		MsgAlert(STR0023) //" Este Produto está configurado para nao imprimir etiqueta "
		Return .F.
	EndIf

	nQtde	:= SC2->(C2_QUANT-C2_QUJE)
	nQE		:= CBQEmbI()
	nQE		:= If(Empty(nQE),1,nQE)
	nQVol	:= Int(nQtde)
	nResto  :=nQtde

	aLbx:={{.f.,SB1->B1_COD,SB1->B1_DESC, Str(nQtde,nT,nD),Str(nQE,nT,nD),SC2->C2_LOCAL,PAD( SC2->C2_NUM + if(Empty(SC2->C2_DATRF),DTOS(SC2->C2_DATPRI),DTOS(SC2->C2_DATRF)),nTamLote),"",Space(Tamsx3("C5_NUM")[1]),"SC2",SC2->(Recno())}}
	oLbx:SetArray( aLbx )
	oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
	oLbx:Refresh()

Return .t.

Static Function ListBoxMar(oDlg)
	LOCAL oChk1
	LOCAL oChk2
	LOCAL lChk1 := .F.
	LOCAL lChk2 := .F.
	LOCAL oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
	LOCAL oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL oP
	LOCAL lAlter := .T.

/* " ","Produto","Descrição","Qtd.","Cópias","Armazem","Lote","Endereço","Pedido","Origem","Id" */

	@ 10,10 LISTBOX oLbx FIELDS HEADER aTitle[1], aTitle[2], aTitle[3],aTitle[4],aTitle[5],aTitle[6],aTitle[7],aTitle[8],aTitle[9],aTitle[10],aTitle[11]  SIZE 230,095 OF oDlg PIXEL ;
		ON dblClick(aLbx[oLbx:nAt,1] := !aLbx[oLbx:nAt,1])

	oLbx:SetArray( aLbx )
	oLbx:bLine	:= {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
	oLbx:align	:= CONTROL_ALIGN_ALLCLIENT

	oP := TPanel():New( 028, 072, ,oDlg, , , , , , 120, 20, .F.,.T. )
	oP:align:= CONTROL_ALIGN_BOTTOM

	If ExistBlock("ACDI11VA")
		lAlPe := ExecBlock("ACDI11VA",.F.,.F.)
		If ValType(lAlPe) == "L"
			lAlter := lAlPe
		EndIf
	EndIf

	@ 5,010  BUTTON STR0031	 SIZE 55,11 ACTION FormProd(1) WHEN lAlter OF oP PIXEL //"Alterar"
	@ 5,080  BUTTON STR0032	 SIZE 55,11 ACTION FormProd(2) when _lCopia OF oP PIXEL //"Copiar"

	@ 5,160 CHECKBOX oChk1 VAR lChk1 PROMPT STR0033 SIZE 70,7 	PIXEL OF oP ON CLICK( aEval( aLbx, {|x| x[1] := lChk1 } ),oLbx:Refresh() ) //"Marca/Desmarca Todos"
	@ 5,230 CHECKBOX oChk2 VAR lChk2 PROMPT STR0034 	SIZE 70,7 	PIXEL OF oP ON CLICK( aEval( aLbx, {|x| x[1] := !x[1] } ), oLbx:Refresh() ) //"Inverter a seleção"

Return

Static Function FormProd(nopcao)
	LOCAL oOk		:= LoadBitmap( GetResources(), "LBOK" ) //CHECKED    //LBOK  //LBTIK
	LOCAL oNo		:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
	LOCAL aRet		:= {}
	LOCAL aParamBox := {}
	LOCAL cPedido   := aLbx[oLbx:nAt,9]
	LOCAL cProduto	:= aLbx[oLbx:nAt,2]
	LOCAL cDescr	:= alltrim(aLbx[oLbx:nAt,3])
	LOCAL nQEmb		:= Val(aLbx[oLbx:nAt,5])
	LOCAL cQtde		:= aLbx[oLbx:nAt,4]
	LOCAL cLOCAL	:= aLbx[oLbx:nAt,6]
	LOCAL cEndereco := aLbx[oLbx:nAt,8]
	LOCAL cLote		:= aLbx[oLbx:nAt,7]
	LOCAL cSLote    := Space(nTamEnder)

	LOCAL nAt		:= oLbx:nAt

	LOCAL nMv
	LOCAL _nIdx     := 0
	LOCAL aMvPar	:={}
	LOCAL lOk       := .F.
	LOCAL nT		:= TamSx3("D3_QUANT")[1]
	LOCAL nD		:= TamSx3("D3_QUANT")[2]

	LOCAL _aIDBobina := {}

	For nMv := 1 To 40
		aAdd( aMvPar, &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) )
	Next nMv

	aParamBox :={{1,STR0005	   ,cProduto, ""       , "",""    ,".F.",  60,.F.},; //"Produto"
	{1,"Descrição",cDescr  , ""       , "",""    ,".F.", 110,.T.},; //"Descrição"
	{1,STR0035	   ,cQtde   , ""       , "",""    ,if( cOpcSel == "Nota Fiscal", ".F.",".F."),   0,.T.},; //"Quantidade"
	{1,"Cópias"   ,nQEmb  	, "@E 9999", "",""    ,".T.",   0,.T.},;  //"Qtd por Embalagem"
	{1,STR0045    ,cLOCAL 	, ""       , "", "NNR",".F.",   0,.F.},; //"Armazem"
	{1,STR0030	   ,cLote  	, ""       , "", "SBF",if( cOpcSel == "Produto Avulso", ".F.",".F."),  60,.F.};  //"Lote"
	}

	If cOpcSel = "Ordem de Producao"

		aAdd( aParamBox,{1,"Pedido"   ,cPedido	,"",""	,"SC5",".T.", 50,	.F.} ) //"Pedido"

	ElseIf cOpcSel = "Nota Fiscal"

		cPedido := Pad(cPedido, 15)
		aAdd( aParamBox,{1,"ID Bobina"   ,cPedido	,"",""	,"SC4",".F.", 50,	.F.} ) //"Pedido"

		If nOpcao == 2

			_cFile := cGetFile( 'Arquivos (*.csv)  | *.csv ',;
				'Selecione o arquivo a ser importado',;
				,;
				,;
				.T.,;
				GETF_LOCALHARD+GETF_NETWORKDRIVE;
				)

			If FT_FUse( _cFile ) < 0

				MsgInfo("Erro na abertura do arquivo!")
				Return( .F. )

			End

			FT_FGoTop()
			_lPri    := .T. /*  Atualiza o primeiro item lido */

			While ! ( FT_FEof() )

				_cBuffer := FT_FReadLn()
				_nIdx    := Len( aLbx )

				MontaArrray( @_aIDBobina )

				If Len( _aIDBobina ) == 4

					If rTrim(aLbx[ nAt ][ 2 ]) == rtrim( _aIDBobina[ 1 ] ) .And.;
							rTrim(MV_PAR01) == rtrim( _aIDBobina[ 4 ] )

						If _lPri

							aLbx[ nAt ][ 4 ] := Str(Val(ltrim(( replace( _aIDBobina[ 2 ], "," , "." ) ))),nT,nD)
							aLbx[ nAt ][ 9 ] := _aIDBobina[ 3 ]
							_lPri := .F.

						Else

							aAdd( aLbx, aClone( aLbx[ nAt ] ) )
							_nIdx ++
							aLbx[ _nIdx ][ 4 ] := Str(Val(ltrim(( replace( _aIDBobina[ 2 ], "," , "." ) ))),nT,nD)
							aLbx[ _nIdx ][ 9 ] := _aIDBobina[ 3 ]

						End

					Else

						MsgInfo('Produto selecionado, não existe no arquivo a ser importado (' + _aIDBobina[ 3 ] + ')!','Produto')

					End

				Else

					MsgInfo('Erro na estrutura do arquivo importado, favor verificar o contéudo, conforme layout (Produto;Qtde;ID Bobina).','Estrutura')

				End

				FT_FSkip()

			End

			FT_FUse()
			nAT := _nIdx
			aLbx := aSort( aLbx,,,{|x,y| x[2] < y[2] } )
			oLbx:SetArray( aLbx )
			oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
			oLbx:Refresh()
			Return( .T. )

		End

	ElseIf cOpcSel = "Produto Avulso"

		aAdd( aParamBox,{1,"Endereço" ,cEndereco	,"",""	,"SBE",if( cOpcSel == "Produto Avulso", ".F.",".F."), 40,	.F.} ) //"Endereço"

	End

	While !lOk
		If ! ParamBox(aParamBox,If(nopcao == 1,STR0031,STR0032),@aRet,,,,,,,,.f.)    //"Alterar","Copiar"
			For nMv := 1 To Len( aMvPar )
				&( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
			Next nMv
			oLbx:SetArray( aLbx )
			oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
			oLbx:Refresh()
			Return
		EndIf

		aParamBox[3,3] := str(val(aRet[3]),nT,nD)
		aParamBox[4,3] := str(aRet[4],nT,nD)

		If cOpcSel = "Produto Avulso"

			aParamBox[6,3] := aRet[6]

		ElseIf cOpcSel = "Ordem de Producao"

			aParamBox[7,3] := aRet[7]
			aLbx[nAt,9]    := aRet[7]

		End

		lOk := .T.

	End

	nQEmb := aRet[4]

	If Empty(nQEmb)

		If MsgYesNo(STR0039) //"Quantidade informada igual a zero, deseja excluir esta linha?"
			aDel(aLbx,nAt)
			aSize(aLbx,len(albx)-1)
		EndIf

	Else

		cLOCAL	:= aRet[5]
		cLote 	:= aRet[6]
		cSLote  := "" //aRet[6]
		dValid	:= "" //aRet[7]
		cNumSer := "" //aRet[8]

		If cOpcSel == "Produto Avulso"

			cEndereco := aRet[ 7 ]

		Else

			cEndereco := ""

		End

		aLbx[nAt,5] := str(nQEmb,nT,nD)

	EndIf

	oLbx:SetArray( aLbx )
	oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11]}}
	oLbx:Refresh()

	For nMv := 1 To Len( aMvPar )
		&( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
	Next nMv
Return .t.

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ VldaLbx  ³ Autor ³      TOTVS S/A        ³ Data ³ 01/01/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa para Validar a parametrizacao por produto         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ VldaLbx()                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function VldaLbx()

	LOCAL nx
	LOCAL nMv
	LOCAL lACDI11VL := .T.

	SB1->(DbSetOrder(1))

	For nX := 1 to Len(aLbx)
		If aLbx[nx,1] .and. ! Empty(aLbx[nX,3])
			exit
		EndIf
	Next

	If nX > len(aLbx)
		MsgAlert(STR0040) //"Necessario marcar pelo menos um item com quantidade para imprimir!"
		Return .f.
	EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de Entrada para validacoes especificas ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ExistBlock("ACDI11VL")
		lACDI11VL := ExecBlock("ACDI11VL",.F.,.F.,{cOpcSel,aLbx})
		If ValType(lACDI11VL) == "L" .And. !lACDI11VL
			Return  .F.
		EndIf
	EndIf

	aSvPar := {}

	For nMv := 1 To 40
		aAdd( aSvPar, &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) )
	Next nMv

Return .t.

Static Function Imprime( cOrigem, cCodPt, aRetImp, nOrigem )
	LOCAL lRet		:= .T.
	LOCAL cLocImp 	:= IIf( nOrigem == 4, aRetImp[ 1 ], MV_PAR01 )
	LOCAL cProduto
	LOCAL cLOCAL := Space(nTamArm)
	LOCAL nQtde
	LOCAL nQE
	LOCAL nQVol
	LOCAL nResto
	LOCAL cAliasOri
	LOCAL nRecno
	LOCAL cLote  		:= Space(nTamlote)
//LOCAL cSLote 		:= Space(nTamSlote)
//LOCAL cNumSerie  	:= Space(nTamSerie)
	LOCAL cEndereco  	:= Space(nTamEnder)
//LOCAL dValid     	:= CTOD("  /  /  ")
	LOCAL nMv
	LOCAL cNotaFisc 	:= ""
	LOCAL cSerieNFisc   := ""
	LOCAL cForn 		:= ""
	LOCAL cLojaForn 	:= ""
	LOCAL aAreaSDB		:= SDB->( GetArea() )
	LOCAL aAreaCB0		:= CB0->( GetArea() )
	LOCAL cOriNFLang	:= STR0001
	LOCAL _nPos         := 0 as Integer
	LOCAL nX            := 0 as Integer

	PRIVATE _nPnt       := 0 as integer

	Default cCodPt		:= ''

	dbSelectArea( 'SDB' )
	SDB->( dbSetOrder( 1 ) )

	If ! CBYesNo(STR0041,STR0042)  //"Confirma a Impressao de Etiquetas"###"Aviso"
		Return .f.
	EndIf

	If ! CB5SetImp(cLocImp)
		MsgAlert(STR0043+cLocImp+STR0044) //"LOCAL de Impressão "###" nao Encontrado!"
		Return .f.
	Endif

	For nMv := 1 To Len( aSvPar )
		&( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aSvPar[ nMv ]
	Next nMv

	If cOrigem == cOriNFLang
		cNotaFisc 		:= aSvPar[1]
		cSerieNFisc 	:= aSvPar[2]
		cForn 			:= aSvPar[3]
		cLojaForn 		:= aSvPar[4]
	Else
		cNotaFisc 		:= ""
		cSerieNFisc 	:= ""
		cForn 			:= ""
		cLojaForn 		:= ""
	EndIf

	If cOrigem == cOriPalLang
		dbSelectArea( 'CB0' )
		CB0->( dbSetOrder( 5 ) )
		CB0->( dbSeek( FWxFilial( "CB0" ) + cCodPt )  )

		If ExistBlock("IMG10")
			ExecBlock("IMG10",,,{ cCodPt } )
		EndIf

		If ExistBlock('IMG00')
			ExecBlock("IMG00",,,{ "ACDV230", cCodPt } )
		EndIf

	ElseIf cOpcSel == "Ident. de Endereço Físico"

	/*
	Parametros do Padrão
	cCondicao := cCondicao + "BE_LOCAL     >= '"+ If(nID==NIL,mv_par01,cCodAlmox) +"' .And. "
	cCondicao := cCondicao + "BE_LOCAL     <= '"+ If(nID==NIL,mv_par02,cCodAlmox) +"' .And. "
	cCondicao := cCondicao + "BE_LOCALIZ   >= '"+ If(nID==NIL,mv_par03,cCodLoc) +"' .And. "
	cCondicao := cCondicao + "BE_LOCALIZ   <= '"+ If(nID==NIL,mv_par04,cCodLoc) +"' "
	Parametros da Customização
	PRIVATE cAlmDe  := Space(TamSX3("BE_LOCAL")[1])
	PRIVATE cAlmAte := Space(TamSX3("BE_LOCAL")[1])
	PRIVATE cEndDe  := Space(TamSX3("BE_LOCALIZ")[1])
	PRIVATE cEndAte := Space(TamSX3("BE_LOCALIZ")[1])
	*/

		MV_PAR05 := MV_PAR01 /* Ajuste compatibilizar o parametro 5 com o código da impressora */
		MV_PAR01 := aRetAv[1]   /* Ajuste compatibilizar o parâmetro do armazém De */
		MV_PAR02 := aRetAv[2]  /* Ajuste compatibilizar o parâmetro do armazém Até*/
		MV_PAR03 := aRetAv[3]   /* Ajuste compatibilizar o parâmetro do Endereço De*/
		MV_PAR04 := aRetAv[4]  /* Ajuste compatibilizar o parâmetro do Endereço Atpe */
		ACDI020LO() /* Imprime endereços via rotina padrão e ponto de entrada IMG02 */

	Else

		SB1->(DbSetOrder(1))
		_nPos := Len( aLbx )

		For nX := 1 To _nPos

			If ! aLbx[nx,1]
				Loop
			EndIf

			_nPnt := nX

			cProduto:= aLbx[nx,2]
			nQtde	:= Val( aLbx[nx,4] )

			If Empty(nQtde)
				Loop
			EndIf

			nQE		:= val(aLbx[nx,4])
			nResto	:= val(aLbx[nx,5])
			nQVol 	:= val(aLbx[nx,4])
			cLOCAL	:= aLbx[nx,6]
			cLote	:= aLbx[nx,7]
			cAliasOri := aLbx[nx,10]
			nRecno    := aLbx[nx,11]

			( cAliasOri )->( dbGoto( nRecno ) ) //posiciona na tabela de origem da informação
			SB1->( dbSeek( xFilial('SB1') + cProduto ) )

			If cOrigem == cOriNFLang
				If nQVol > 0
					Do Case
					Case Empty( cEndereco )
						If !SDB->( dbSeek( FWxFilial( 'SDB' ) + ( cAliasOri )->D1_COD + ( cAliasOri )->D1_LOCAL + ( cAliasOri )->D1_NUMSEQ + ( cAliasOri )->D1_DOC + ( cAliasOri )->D1_SERIE + ( cAliasOri )->D1_FORNECE + ( cAliasOri )->D1_LOJA ) )
							ExecBlock("IMG01",,,aLbx[nx] )
							If nResto > 0
								ExecBlock("IMG01",,,aLbx[nx])
							EndIf
						Else
							ExecBlock("IMG01",,,)
							If nResto > 0
								ExecBlock("IMG01",,,aLbx[nx])
							EndIf
						EndIf

					Case !( Empty( cEndereco ) )
						ExecBlock("IMG01",,,aLbx[nx] )
						If nResto > 0
							ExecBlock("IMG01",,,aLbx[nx] )
						EndIf
					EndCase
				EndIf
			Else

				If nResto > 0
					ExecBlock("IMG01",,,aLbx[nx])
				EndIf

			EndIf
		Next nX
	EndIf

	MSCBCLOSEPRINTER()
	RestArea( aAreaSDB )
	RestArea( aAreaCB0 )
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³I011Vld   ³ Autor ³ Materiais             ³ Data ³ 13/01/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Validacoes do get do produto                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ lRastro  - Indica se produto controla lote                 ³±±
±±³          ³ cCodProd - Codigo do produto                               ³±±
±±³          ³ nQuant   - Quantidade de etiquetas                         ³±±
±±³          ³ nQtdEmb  - Quantidade por embalagem                        ³±±
±±³          ³ cLOCAL   - Armazem                                         ³±±
±±³          ³ cLote    - Lote                                            ³±±
±±³          ³ cSLote   - Sublote                                 		  ³±±
±±³          ³ dDtVld   - Data de validade                                ³±±
±±³          ³ cNumSerie- Numero de serie                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ lRet - logico                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function I011Vld(lRastro,cCodProd, nQuant, nQtdEmb,cLOCAL,cLote, cSLote, dDtVld,cNumSerie,cEndereco)

	LOCAL aAreaAnt := GetArea()
	LOCAL aAreaSB8 := SB8->(GetArea())
	LOCAL aAreaSB2 := SB2->(GetArea())
	LOCAL aAreaSBF := SBF->(GetArea())
	LOCAL lRet     := .T.

	If !Empty(cEndereco)
		SBF->(DbSetOrder(1)) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
		If !SBF->(Dbseek(xFilial("SBF")+cLOCAL+cEndereco+cCodProd+cNumSerie+cLote+cSLote))
			Aviso(STR0064,STR0063,{STR0061}, 1) // "Endereço Invalido";"Não existe saldos para o endereço informado"; "OK"
			lRet := .F.
		EndIF
	ElseIf LOCALiza(cCodProd) .And. Empty(cEndereco)
		Aviso(STR0062,STR0065,{STR0061}, 1) // "Endereco ";"Informe o endereco do produto"; "OK"
		lRet := .F.
	EndIf

	If nQuant <= 0 .Or. nQtdEmb <= 0
		Aviso(STR0048,STR0049,{STR0061}, 1) // "Quantidade invalida" ; "Verifique se os valores de quantidade são maiores que zero." "OK"
		lRet := .F.
	EndIf

	If lRet
		NNR->(DbSetOrder(1)) // FILIAL + CODIGO
		If ! NNR->(MsSeek(xFilial("NNR")+cLOCAL))
			Aviso(STR0050,STR0051,{STR0061}, 1) // "Armazem invelido","Informe um armazem existente." "OK"
			lRet := .F.
		EndIf
	EndIf

	If lRet
		SB2->(DbSetOrder(1)) // FILIAL + COD + LOCAL
		lRet := SB2->(MsSeek(xFilial("SB2")+cCodProd+cLOCAL))
		If !lRet
			Aviso(STR0052,STR0053,{STR0061}, 1) // "Sem saldo"," Armazem nao existente para esse produto" "OK"
		ElseIf SaldoMov() <= 0
			// "Sem saldo disponivel"," Produto não possui saldo disponivel neste armazem. Somente sao geradas etiquetas para produtos com saldo disponivel em estoque." "OK"
			Aviso(STR0054,STR0055+STR0056,{STR0061}, 2)
			lRet := .F.
		EndIf

	EndIf

	If lRet .And. lRastro
		SB8->(dbSetOrder(5)) // FILIAL + PRODUTO + LOTECTL + NUMLOTE + DTVALID
		If (!SB8->(DbSeek(xFilial("SB8")+cCodProd+cLote+cSLote+ DTOS(dDtVld), .T.))) .Or. Empty(cLote) .Or. Empty(dDtVld) .Or. IIF(Rastro(cCodProd,"S"),Empty(cSLote),.F.)
			//"Lote invalido","Pressione a tecla F4 no campo de lote para carregar automaticamente as informacoes."
			//"Verifique se estao corretas as informaoes sobre o armazem, numero do lote, sublote e data de validade." "OK"
			//"Somente sao geradas etiquetas para lotes validos e com saldo em estoque. "
			Aviso(STR0057,STR0058+STR0059+STR0060,{STR0061}, 2)
			lRet := .F.
		EndIf

	EndIf

	RestArea(aAreaSB2)
	RestArea(aAreaSB8)
	RestArea(aAreaSBF)
	RestArea(aAreaAnt)

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ConsSerNf ³ Autor ³ Materiais             ³ Data³01/10/2015 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Consulta de Seies				                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cAlias    - Tabela que irá realizar a consutla             ³±±
±±³          ³ Documento -                            					  ³±±
±±³          ³ cSerie    - Serie que é informada pelo usuario			  ³±±
±±³								 para realizar a conulta                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ cSerie - Caractere                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function ConsSerNf(tabela, cSerie, numero, cFornec, cLojaFor )

	LOCAL aSeries 	:= {}
	LOCAL aHeader	:= {}

	aAdd(aHeader,{ STR0001, "F1_DOC",     '@!',  9,  , , , "C",,})
	aAdd(aHeader,{ STR0002, "F1_SERIE",   '!!!', 14, , , , "C",,})
	aAdd(aHeader,{ "Emissão","F1_EMISSAO",  '@!',  8,  , , , "D",,})

	If (tabela == "SF1")

		SF1->(dbSetOrder(1))
		SF1->(dbSeek(xFilial('SF1') + numero + cSerie + cFornec + cLojaFor ))
		While !SF1->(Eof()) .And. AllTrim(SerieNfId("SF1", 2, "F1_SERIE")) == AllTrim(cSerie)  .And. SF1->F1_DOC == numero .And. SF1->F1_FORNECE == Padr( cFornec, TamSx3( 'F1_FORNECE' )[1] ) .And. SF1->F1_LOJA == Padr( cLojaFor, TamSx3( 'F1_LOJA' )[1] )
			Aadd(aSeries, {SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_EMISSAO})
			SF1->(dbSkip())
		EndDo


		If(Len(aSeries)=1)
			cSerie := aSeries[1][2]
		ElseIf(Len(aSeries)>1)
			//mostra tela para escolha

			DEFINE MSDIALOG oDlg TITLE OemToAnsi("Escolha de Notas") FROM 009,000 TO 025,060 OF oMainWnd

			oGet := MsNewGetDados():New(005,005,100,232,5,,,,,,,,,,oDlg,aHeader,aSeries)

			DEFINE SBUTTON FROM 105, 203 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg

			ACTIVATE MSDIALOG oDlg CENTERED

			cSerie := aSeries[oGet:nAt][2]

		EndIf

	EndIf

Return cSerie

Static Function AWzVAv()


// Carga dos parametros para chamada ACDI020LO() next wizard

Return( .T. )


/*

    Inclui parâmetros para tratar impressão do logotipos e tipo de etiqueta
  
*/
Static Function ChkParm()

	If Len( SuperGetMV("MV_XLOGETI",,{}) ) == 0

		RecLock("SX6", .T.)
		SX6->X6_FIL     := Space(Len(SX6->X6_FIL))
		SX6->X6_VAR     := "MV_XLOGETI"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "Retorna logotipo a ser utilizado nas etiquetas (F)"
		SX6->X6_DESC1   := "Forest ou (R) Revita, {Empresa,Tipo} "
		SX6->X6_CONTEUD := '{{"010101","F"},{"080101","R"}}'
		SX6->X6_CONTSPA := '{{"010101","F"},{"080101","R"}}'
		SX6->X6_CONTENG := '{{"010101","F"},{"080101","R"}}'
		SX6->X6_PROPRI  := "U"
		SX6->X6_PYME    := "S"
		SX6->( MSUnLock() )

	End

	If Len( SuperGetMV("MV_XFORMA4",,{}) ) == 0

		RecLock("SX6", .T.)
		SX6->X6_FIL     := Space(Len(SX6->X6_FIL))
		SX6->X6_VAR     := "MV_XFORMA4"
		SX6->X6_TIPO    := "C"
		SX6->X6_DESCRIC := "Retorna modelo da impressão ser utilizado nas eti-"
		SX6->X6_DESC1   := "quetas (A) A4 ou (T) Térmica, {Empresa,Modelo} "
		SX6->X6_CONTEUD := '{{"010101","T"},{"080101","A"}}'
		SX6->X6_CONTSPA := '{{"010101","T"},{"080101","A"}}'
		SX6->X6_CONTENG := '{{"010101","T"},{"080101","A"}}'
		SX6->X6_PROPRI  := "U"
		SX6->X6_PYME    := "S"
		SX6->( MSUnLock() )

	End

Return( NIL )


 /*
 
    Lê arquivo contendo as informações referente aos IDs de identificação das bobinas
 
 */


Static Function MontaArrray( _aField )

	LOCAL _nPos := 1
	LOCAL _nOld := 1
	LOCAL _nTam := 0
	LOCAL _nLen := Len( _cBuffer )

	_aField := {}

	While .T.

		_nPos := At( ';', Substr( _cBuffer, _nOld, _nLen ) )


      /* Caso a empresa decida substituir o separador pesquiso pela virgula */
		If _nPos = 0
			_nPos := At( ',', Substr( _cBuffer, _nOld, _nLen ) )
		End

      /* Caso a empresa decida substituir o separador pesquiso pelo # */

		If _nPos = 0
			_nPos := At( '#', Substr( _cBuffer, _nOld, _nLen ) )
		End

		If _nPos <> 0

			_nTam := _nPos
			_nTam --

		Else

			_nTam := _nLen
			_nTam ++

		End

		aAdd( _aField, Substr( _cBuffer, _nOld, _nTam  ) )

		If _nPos <> 0

			_nOld += _nPos
			_nLen := Len( Substr( _cBuffer, _nOld ) )
			_nPos ++

		Else

			Exit

		End

	End

Return( _aField )

