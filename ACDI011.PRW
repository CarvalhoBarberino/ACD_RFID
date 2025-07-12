#INCLUDE "ACDI011.ch"
#Include "Protheus.ch"
#Include "ApWizard.ch"


/*±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
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
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function ACDI011(nOrigem,aParIni)
Local oWizard
Local oPanel
Local nTam
Local nTamDoc:= TamSX3("F1_DOC")[1]
Local nSerie := TAmSX3("F1_SERIE")[1]
Local nCodigo:= TamSX3("A2_COD")[1]
Local nLoja  := TamSX3("A2_LOJA")[1]
Local lRun 	 := .F.
Local oOrigem
Local aOrigem	:= {}

Local aparNF	:= {	{1,STR0001 		,nTamDoc ,"","","CBW"	,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Nota Fiscal"
						{1,STR0002 		,nSerie  ,"","",		,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Serie"
						{1,STR0003		,nCodigo ,"","","SA2"	,If(aParIni==NIL,".T.",".F."),0,.F.},; //"Fornecedor"
						{1,STR0004		,nLoja   ,"","",		,If(aParIni==NIL,".T.",".F."),0,.F.} } //"Loja"

Local aRetNF	:= {Space(nTamDoc),Space(nSerie),Space(nCodigo),Space(nLoja)}

Local aParPR	:= {{1,STR0005 ,Space(Tamsx3("B1_COD")[1]),"","","SB1"	,If(aParIni==NIL,".T.",".F."),115,.F.}} //"Produto"
Local aRetPR	:= {Space(Tamsx3("B1_COD")[1])}

Local aParOP	:= {{1, STR0007 ,Space(13),"","","SC2"	,If(aParIni==NIL,".T.",".F."),60,.F.}}
Local aRetOP	:= {Space(13)}

Local aParImp	:= {{1, STR0006	,Space(06),"","","CB5"	,".T.",0,.F.}} //"Local de Impressão"
Local aRetImp	:= {Space(6)}

Local aParPt	:= {{1, STR0066 , CriaVar( "CB0_PALLET", .F. ),"","","CB0001"	,If( aParIni == NIL, ".T.", ".F." ), 60, .F. } } //"Pallet"
Local aRetPt	:= { CriaVar( "CB0_PALLET", .F. ) }
Local cCodPt	:= CriaVar( "CB0_PALLET", .F. )
Local aParam	:= {} 
Local aRetPE	:= {}

Local nx:= 1

Private nTamArm   := TamSX3("B2_LOCAL")[1]
Private nTamLote  := TamSX3("B8_LOTECTL")[1]
Private nTamSLote := TamSX3("B8_NUMLOTE")[1]
Private nTamSerie := TamSX3("BF_NUMSERI")[1]
Private nTamEnder := Tamsx3("BE_LOCALIZ")[1]

Private cCondSF1:= ' 1234567890'  // variavel utilizada na consulta sxb CBW, favor nao remover esta linha
Private oLbx
Private aLbx	:= {{.f., Space(Tamsx3("B1_COD")[1]),Space(20),Space(10),Space(10),Space(10),Space(nTamArm),Space(nTamLote),Space(nTamSlote),CTOD("  /  /  "),Space(nTamSerie),Space(nTamEnder)}}
Private aSvPar	:= {}
Private cOpcSel	:= ""  // variavel disponivel para infomar a opcao de origem selecionada

DEFAULT nOrigem := 1

aParam := { {STR0001	,aParNF,aRetNF,{|| AWzVNF() } },; //"Nota Fiscal"
			{STR0005	,aParPR,aRetPR,{|| AWzVPR() } },; //"Produto"
			{STR0007	,aParOP,aRetOP,{|| AWzVOP() } },; //"Ordem de Producao"
			{STR0066	,aParPt,aRetPt,{|| ( cCodPt := '', AWzVPt( @cCodPt, oWizard, @aParam, nOrigem ) ) } } } //"Pallet"

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

DEFINE WIZARD oWizard TITLE STR0008 ; //"Etiqueta de Produto ACD"
       HEADER STR0009 ; //"Rotina de Impressão de etiquetas termica."
       MESSAGE "";
       TEXT STR0010 ; //"Esta rotina tem por objetivo realizar a impressao das etiquetas termicas de identificação de produto no padrão codigo natural/EAN conforme as opcoes disponives a seguir."
       NEXT {|| .T.} ;
		 FINISH {|| .T. } ;
       PANEL

   // Primeira etapa
   CREATE PANEL oWizard ;
          HEADER STR0011 ; //"Informe a origem das informações para impressão"
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
          HEADER STR0012 ; //"Preencha as solicitações abaixo para a seleção do produto"
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
				ParamBox(aParNF,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Parâmetros..."
			Case nx == 2
				ParamBox(aParPR,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Parâmetros..."	
			Case nx == 3
				ParamBox(aParOP,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"Parâmetros..."
			Case nx == 4
				ParamBox(aParPt,STR0013,aParam[nX,3],,,,,,&("oP"+str(nx,1)))		 //"ParĞ²metros..."
		EndCase
		&("oP"+str(nx,1)):Hide()
	Next
	
   CREATE PANEL oWizard ;
          HEADER STR0014 ; //"Parametrização por produto"
          MESSAGE STR0015 ; //"Marque os produtos que deseja imprimir"
          BACK {|| .T. } ;
          NEXT {|| aRetImp  := {Space(6)},VldaLbx()} ;
          FINISH {|| .T. } ;
          PANEL
   oPanel := oWizard:GetPanel(4)       
   ListBoxMar(oPanel)
                        
   CREATE PANEL oWizard ;
          HEADER STR0016 ; //"Parametrização da impressora"
          MESSAGE STR0017 ; //"Informe o Local de Impressão"
          BACK {||  IIf( nOrigem == 4, ( oWizard:GetPanel(4):Hide(), oWizard:SetPanel( 3 ), oWizard:GetPanel(3):Show() ), .T. )  } ;
          NEXT {|| Imprime( aParam[nOrigem,1], cCodPt, aRetImp, nOrigem ) } ;
          FINISH {|| .T.  } ;
          PANEL
   oPanel := oWizard:GetPanel(5)       
   ParamBox(aParImp,STR0013,aRetImp,,,,,,oPanel)	 //"Parâmetros..."
   
     CREATE PANEL oWizard ;
          HEADER STR0018 ; //"Impressão Finalizada"
          MESSAGE "" ;
          BACK {|| .T. } ;
          NEXT {|| .T. } ;
          FINISH {|| .T.  } ;
          PANEL
   


ACTIVATE WIZARD oWizard CENTERED

Return                                           

Static Function A11WZIniPar(nOrigem, aParIni,aParam)
Local nX
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
Local cNota := Padr(MV_PAR01,TamSx3("F1_DOC")[1])
Local cForn := Padr(MV_PAR03,TamSx3("A2_COD")[1])
Local cLoja := Padr(MV_PAR04,TamSx3("A2_LOJA")[1])    
Local cSerie:= ConsSerNf("SF1", MV_PAR02, cNota, cForn, cLoja )//Padr(MV_PAR02,3)
Local nQE
Local nQVol
Local nResto               
Local oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
Local oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO   
Local nT	:= TamSx3("D3_QUANT")[1]
Local nD	:= TamSx3("D3_QUANT")[2] 

If Empty(cNota+cSerie+cForn+cLoja)
  	MsgAlert(STR0019) //" Necessario informar a nota e o fornecedor. "
 	Return .F.
EndIf

SF1->(DbSetOrder(1))
If !SF1->(DbSeek(xFilial('SF1')+cNota+cSerie+cForn+cLoja))
  	MsgAlert(STR0020) //" Nota fiscal não encontrada. "
  	Return .F.
EndIf       

aLbx:={}
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
	nQVol   := Int(SD1->D1_QUANT/nQE)
	nResto  := SD1->D1_QUANT%nQE
	If nResto >0
	   nQVol++
	EndIf
	SD1->(aadd(aLbx,{.f.,D1_COD,Str(SD1->D1_QUANT,nT,nD),Str(nQe,nT,nD),Str(nResto,nT,nD),Str(nQVol,nT,nD),SD1->D1_LOCAL,SD1->D1_LOTECTL,SD1->D1_NUMLOTE,SD1->D1_DTVALID,Space(nTamSerie),Space(nTamEnder),"SD1",Recno(),NIL,NIL,NIL}))  
	SD1->(dbSkip()	)
End     
oLbx:SetArray( aLbx )
oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
oLbx:Refresh()

Return .t.

Static Function AWzVPR()
Local cProduto	:= Padr(MV_PAR01,Tamsx3("B1_COD")[1])
Local oOk		:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
Local oNo		:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO      
Local nT		:= TamSx3("D3_QUANT")[1]
Local nD		:= TamSx3("D3_QUANT")[2] 
Local nQtdEti	:= 0

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
aLbx:={{ .f., SB1->B1_COD,Str(0,nT,nD),Str( nQtdEti,nT,nD),Str(0,nT,nD),Str(0,nT,nD),Space(nTamArm),Space(nTamLote),Space(nTamSLote),CTOD(""),Space(nTamSerie),Space(nTamEnder),"SB1",SB1->(Recno()),Nil,Nil,Nil}}
oLbx:SetArray( aLbx )
oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
oLbx:Refresh()
Return .t.

Static Function AWzVOP()
Local cOp	:= Padr(MV_PAR01,13) 
Local oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
Local oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
Local nQtde
Local nQE
Local nQVol
Local nResto                                            
Local nT	:= TamSx3("D3_QUANT")[1]
Local nD	:= TamSx3("D3_QUANT")[2] 


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
nQVol	:= Int(nQtde/nQE)
nResto  :=nQtde%nQE                                               
If nResto >0
   nQVol++
EndIf

aLbx:={{	.f., SB1->B1_COD,Str(nQtde,nT,nD),Str(nQE,nT,nD),Str(nResto,nT,nD),Str(nQVol,nT,nD),Space(nTamArm),Space(nTamLote),Space(nTamSLote),CTOD("  /  /  "),Space(nTamSerie),Space(nTamEnder),"SC2",SC2->(Recno()),Nil,Nil,Nil}}
oLbx:SetArray( aLbx )
oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
oLbx:Refresh()

Return .t.

Static Function ListBoxMar(oDlg)
Local oChk1
Local oChk2
Local lChk1 := .F.
Local lChk2 := .F.
Local oOk	:= LoadBitmap( GetResources(), "LBOK" )   //CHECKED    //LBOK  //LBTIK
Local oNo	:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
Local oP
Local lAlter := .T.   
Local lAltPe := .T. 
   								   	//"Produto"###"Qtde do Item"###"Qtde Emb."###"Resto"###"Qtde Volumes"###"ARMAZEM"###"Lote"###"SUBLOTE"###"VALIDADE"###"Serie"###"Endereco"
@ 10,10 LISTBOX oLbx FIELDS HEADER " ", STR0005, STR0026,STR0027,STR0028,STR0029,STR0045, STR0030,STR0046,STR0047, STR0002,STR0062,  SIZE 230,095 OF oDlg PIXEL ;
        ON dblClick(aLbx[oLbx:nAt,1] := !aLbx[oLbx:nAt,1])

oLbx:SetArray( aLbx )
oLbx:bLine	:= {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
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
@ 5,080  BUTTON STR0032	 SIZE 55,11 ACTION FormProd(2) OF oP PIXEL //"Copiar"
@ 5,160 CHECKBOX oChk1 VAR lChk1 PROMPT STR0033 SIZE 70,7 	PIXEL OF oP ON CLICK( aEval( aLbx, {|x| x[1] := lChk1 } ),oLbx:Refresh() ) //"Marca/Desmarca Todos"
@ 5,230 CHECKBOX oChk2 VAR lChk2 PROMPT STR0034 	SIZE 70,7 	PIXEL OF oP ON CLICK( aEval( aLbx, {|x| x[1] := !x[1] } ), oLbx:Refresh() ) //"Inverter a seleção"

Return
            
Static Function FormProd(nopcao)
Local oOk		:= LoadBitmap( GetResources(), "LBOK" ) //CHECKED    //LBOK  //LBTIK
Local oNo		:= LoadBitmap( GetResources(), "LBNO" ) //UNCHECKED  //LBNO
Local aRet		:= {}
Local aParamBox := {}  
Local cProduto	:= aLbx[oLbx:nAt,2]
Local nQtde		:= Val(aLbx[oLbx:nAt,3]) 
Local nQEmb		:= Val(aLbx[oLbx:nAt,4]) 
Local cQtde		:= aLbx[oLbx:nAt,3]
Local cQEmb		:= aLbx[oLbx:nAt,4]
Local cLocal	:= aLbx[oLbx:nAt,7]

Local nQVol		:= 0
Local nResto	:= 0
Local cLote		:= aLbx[oLbx:nAt,8]
Local cSLote    := aLbx[oLbx:nAt,9]
Local dDataVld  := aLbx[oLbx:nAt,10]
Local cNumSer	:= aLbx[oLbx:nAt,11]
Local cEndereco := aLbx[oLbx:nAt,12]
Local nAt		:= oLbx:nAt  

Local nMv
Local aMvPar	:={}
Local lRastro	:= Rastro(cProduto)
Local lSLote    := Rastro(cProduto, 'S')
Local lEndereco := Localiza(cProduto)
 
Local lEndere 	:= Localiza(cProduto) 
Local lOk       := .F.
Local nT		:= TamSx3("D3_QUANT")[1]
Local nD		:= TamSx3("D3_QUANT")[2] 

Set Key VK_F4 TO I011F4Lote()

For nMv := 1 To 40
     aAdd( aMvPar, &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) )
Next nMv                     
                       
aParamBox :={	{1,STR0005	,cProduto	,""		,""		,""   	,".F."            	,00,	.F.},; //"Produto"
				{1,STR0035	,cQtde 	    ,""		,"" 	,"" 	,".T."             	,00,	.T.},; //"Quantidade"
				{1,STR0036	,cQEmb  	,""		,""  	,""   	,".T."             	,00,	.T.},;  //"Qtd por Embalagem"
				{1,STR0045  ,cLocal 	,"",""	,"NNR"	,".T."                    	,00,	.F.},; //"Armazem"
				{1,STR0030	,cLote  	,"",""	,""	  	,If(lRastro,".T.",".F.")  	,00,	.F.},; //"Lote"
				{1,STR0046  ,cSLote 	,"",""	,""	  	,If(lSLote,".T.",".F.")   	,00,	.F.},; //"SubLote"
				{1,STR0047  ,dDataVld	,"",""	,""	  	,If(lRastro,".T.",".F.")  	,50,	.F.},; //"Data de validade"
				{1,STR0002	,cNumSer 	,"",""	,""	  	,If(lEndere,".T.",".F.")  	,00,	.F.},; //"Serie"
				{1,STR0062,cEndereco	,"",""	,"SBE"	,If(lEndereco,".T.",".F.")  ,50,	.F.} } //"Endereco"
				
While !lOk
	If ! ParamBox(aParamBox,If(nopcao == 1,STR0031,STR0032),@aRet,,,,,,,,.f.)    //"Alterar","Copiar" 
		For nMv := 1 To Len( aMvPar )
	  	  &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
		Next nMv
		oLbx:SetArray( aLbx )
		oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
		oLbx:Refresh()
		Return
	EndIf
	
	aParamBox[2,3] := str(val(aRet[2]),nT,nD)
	aParamBox[3,3] := str(val(aRet[3]),nT,nD)
	aParamBox[4,3] := aRet[4]
	aParamBox[5,3] := aRet[5]
	aParamBox[6,3] := aRet[6]
	aParamBox[7,3] := aRet[7]
	aParamBox[8,3] := aRet[8]
	aParamBox[9,3] := aRet[9]
	
	
	lOk := I011Vld(lRastro,cProduto,val(aRet[2]),val(aRet[3]),aRet[4],aRet[5],aRet[6],aRet[7],aRet[8],aRet[9])
End

nQtde 	:= val(aRet[2])
  
If Empty(nQtde)  
	If nOpcao == 2
		MsgAlert(STR0038) //"Para a copia a quantidade não pode estar em branco!"
	EndIf
	
	If MsgYesNo(STR0039) //"Quantidade informada igual a zero, deseja excluir esta linha?"
	   aDel(aLbx,nAt)
	   aSize(aLbx,len(albx)-1)
   EndIf
Else
	nQEmb	:= val(aRet[3])
	cLocal	:= aRet[4]
	cLote 	:= aRet[5]
	cSLote  := aRet[6]
	dValid	:= aRet[7]
	cNumSer := aRet[8]
	cEndereco:= aRet[9]
	

	nQVol	:= Int(nQtde/nQEmb)  
	nResto	:= nQtde%nQEmb
	
	If nResto >0
	   nQVol++
	EndIf
	
	If nOpcao == 2
		aadd(aLbx,aClone(aLbx[nAt]))
		nAt := Len(aLbx)
	EndIf
	  
	aLbx[nAt,3] := str(nQtde,nT,nD)
	aLbx[nAt,4] := str(nQEmb,nT,nD) 
	aLbx[nAt,5] := str(nResto,nT,nD) 
	aLbx[nAt,6] := str(nQVol,nT,nD) 
	
	aLbx[nAt,7] := cLocal
	aLbx[nAt,8] := cLote
	aLbx[nAt,9] := cSLote
	aLbx[nAt,10]:= dValid
	aLbx[nAt,11]:= cNumSer 
	aLbx[nAt,12]:= cEndereco 

	
EndIf

oLbx:SetArray( aLbx )
oLbx:bLine := {|| {Iif(aLbx[oLbx:nAt,1],oOk,oNo),aLbx[oLbx:nAt,2],aLbx[oLbx:nAt,3],aLbx[oLbx:nAt,4],aLbx[oLbx:nAt,5],aLbx[oLbx:nAt,6],aLbx[oLbx:nAt,7],aLbx[oLbx:nAt,8],aLbx[oLbx:nAt,9],aLbx[oLbx:nAt,10],aLbx[oLbx:nAt,11],aLbx[oLbx:nAt,12]}}
oLbx:Refresh()

For nMv := 1 To Len( aMvPar )
    &( "MV_PAR" + StrZero( nMv, 2, 0 ) ) := aMvPar[ nMv ]
Next nMv
Return .t.          

/*±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
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
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function VldaLbx()

Local nx
Local nMv
Local lACDI11VL := .T.

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
Local lRet		:= .T.
Local cLocImp 	:= IIf( nOrigem == 4, aRetImp[ 1 ], MV_PAR01 )
Local nX 
Local cProduto
Local cLocal := Space(nTamArm)
Local nQtde
Local nQE   
Local nQVol
Local nResto
Local cAliasOri
Local nRecno    
Local cLote  		:= Space(nTamlote)
Local cSLote 		:= Space(nTamSlote)
Local cNumSerie  	:= Space(nTamSerie)
Local cEndereco  	:= Space(nTamEnder)
Local dValid     	:= CTOD("  /  /  ")
Local nMv
Local cNotaFisc 		:= ""
Local cSerieNFisc   	:= ""
Local cForn 			:= ""
Local cLojaForn 		:= ""
Local aAreaSDB		:= SDB->( GetArea() )
Local aAreaCB0		:= CB0->( GetArea() )
Local cOriNFLang		:= STR0001
Local cOriPalLang		:= STR0066

Default cCodPt		:= ''

dbSelectArea( 'SDB' )
SDB->( dbSetOrder( 1 ) )

If ! CBYesNo(STR0041,STR0042)  //"Confirma a Impressao de Etiquetas"###"Aviso"
	Return .f.
EndIf

If ! CB5SetImp(cLocImp)  
	MsgAlert(STR0043+cLocImp+STR0044) //"Local de Impressão "###" nao Encontrado!"
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
Else
	SB1->(DbSetOrder(1))
	For nX := 1 to Len(aLbx)   
		If ! aLbx[nx,1]
			Loop
		EndIf	
		cProduto:= aLbx[nx,2]
		nQtde	:= val(aLbx[nx,3])
		If Empty(nQtde)
			Loop
		EndIf	
		nQE		:= val(aLbx[nx,4])
		nResto	:= val(aLbx[nx,5])
		nQVol 	:= val(aLbx[nx,6])
		If nResto > 0 
			nQVol--
		EndIf	                 
		cLocal		:= aLbx[nx,7]
		cLote	 	:= aLbx[nx,8]
		cSLote    	:= aLbx[nx,9]
		dValid    	:= aLbx[nx,10]
		cNumSerie	:= aLbx[nx,11]
		cEndereco 	:= aLbx[nx,12]
		cAliasOri	:= aLbx[nx,13] 
		nRecno		:= aLbx[nx,14]      

		( cAliasOri )->( dbGoto( nRecno ) ) //posiciona na tabela de origem da informação
		SB1->( dbSeek( xFilial('SB1') + cProduto ) )

		If cOrigem == cOriNFLang
			If nQVol > 0
				Do Case
					Case Empty( cEndereco )
						If !SDB->( dbSeek( FWxFilial( 'SDB' ) + ( cAliasOri )->D1_COD + ( cAliasOri )->D1_LOCAL + ( cAliasOri )->D1_NUMSEQ + ( cAliasOri )->D1_DOC + ( cAliasOri )->D1_SERIE + ( cAliasOri )->D1_FORNECE + ( cAliasOri )->D1_LOJA ) )
							ExecBlock("IMG01",,,{nQE,,,nQVol,IIF(cOrigem == cOriNFLang,cNotaFisc,""),cSerieNFisc,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco,,,( cAliasOri )->D1_ITEM } )
							If nResto > 0
								ExecBlock("IMG01",,,{nResto,,,1,cNotaFisc,cNumSerie,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco,,,( cAliasOri )->D1_ITEM } )
							EndIf	
						Else
							ExecBlock("IMG01",,,{nQE,,, nQVol,SD1->D1_DOC,SD1->D1_SERIE,SD1->D1_FORNECE,SD1->D1_LOJA,SD1->D1_LOCAL,,SD1->D1_NUMSEQ,SD1->D1_LOTECTL,SD1->D1_NUMLOTE,SD1->D1_DTVALID,,,, SDB->DB_NUMSERI,, SDB->DB_LOCALIZ,,0,SD1->D1_ITEM})						
							If nResto > 0
								ExecBlock("IMG01",,,{nResto,,,1,SD1->D1_DOC,SD1->D1_SERIE,SD1->D1_FORNECE,SD1->D1_LOJA,SD1->D1_LOCAL,,SD1->D1_NUMSEQ,SD1->D1_LOTECTL,SD1->D1_NUMLOTE,SD1->D1_DTVALID,,,,SDB->DB_NUMSERI,,SDB->DB_LOCALIZ,,0,SD1->D1_ITEM})
							EndIf
						EndIf

					Case !( Empty( cEndereco ) )
						ExecBlock("IMG01",,,{nQE,,,nQVol,IIF(cOrigem == cOriNFLang,cNotaFisc,""),cSerieNFisc,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco,,,( cAliasOri )->D1_ITEM } )
						If nResto > 0
							ExecBlock("IMG01",,,{nResto,,,1,cNotaFisc,cNumSerie,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco,,,( cAliasOri )->D1_ITEM } )
						EndIf	
				EndCase
			EndIf
		Else
			If nQVol > 0
				ExecBlock("IMG01",,,{nQE,,,nQVol,IIF(cOrigem == cOriNFLang,cNotaFisc,""),cSerieNFisc,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco})
			EndIf
			If nResto > 0
				ExecBlock("IMG01",,,{nResto,,,1,cNotaFisc,cNumSerie,cForn,cLojaForn,cLocal,,,cLote,cSLote,dValid,,,,cNumSerie,,cEndereco})
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
±±³Fun‡…o    ³I011F4Lote³ Autor ³ Materiais             ³ Data ³ 13/01/15 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada da funcao F4LOTE                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function I011F4Lote()

Local cCampo := AllTrim(Upper(ReadVar()))

If cCampo == "MV_PAR05" // LOTE
	F4Lote(,,,"ACDI011",MV_PAR01,MV_PAR04,NIL,"")
ElseIf cCampo == "MV_PAR09" // Endereco
	F4Localiz(,,,   'ACDI011', MV_PAR01, MV_PAR04,MV_PAR02, ReadVar())
EndIF


Return NIL

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
±±³          ³ cLocal   - Armazem                                         ³±±
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
Static Function I011Vld(lRastro,cCodProd, nQuant, nQtdEmb,cLocal,cLote, cSLote, dDtVld,cNumSerie,cEndereco)

Local aAreaAnt := GetArea()
Local aAreaSB8 := SB8->(GetArea())
Local aAreaSB2 := SB2->(GetArea())
Local aAreaSBF := SBF->(GetArea())
Local lRet     := .T.

If !Empty(cEndereco)
	SBF->(DbSetOrder(1)) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
	If !SBF->(Dbseek(xFilial("SBF")+cLocal+cEndereco+cCodProd+cNumSerie+cLote+cSLote))
		Aviso(STR0064,STR0063,{STR0061}, 1) // "Endereço Invalido";"Não existe saldos para o endereço informado"; "OK"
		lRet := .F.
	EndIF 
ElseIf Localiza(cCodProd) .And. Empty(cEndereco) 
	    Aviso(STR0062,STR0065,{STR0061}, 1) // "Endereco ";"Informe o endereco do produto"; "OK"
		lRet := .F.
EndIf

If nQuant <= 0 .Or. nQtdEmb <= 0
	Aviso(STR0048,STR0049,{STR0061}, 1) // "Quantidade invalida" ; "Verifique se os valores de quantidade são maiores que zero." "OK"
	lRet := .F.
EndIf

If lRet
	NNR->(DbSetOrder(1)) // FILIAL + CODIGO
	If ! NNR->(MsSeek(xFilial("NNR")+cLocal))
		Aviso(STR0050,STR0051,{STR0061}, 1) // "Armazem invelido","Informe um armazem existente." "OK"
		lRet := .F.
	EndIf
EndIf

If lRet
	SB2->(DbSetOrder(1)) // FILIAL + COD + LOCAL
	lRet := SB2->(MsSeek(xFilial("SB2")+cCodProd+cLocal))
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
±±³Fun‡…o    ³I011Vld   ³ Autor ³ Materiais             ³ Data³01/10/2015 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Consulta de Seies				                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cAlias    - Tabela que irá realizar a consutla             ³±±
±±³          ³ Documento -                               ³±±
±±³          ³ cSerie    - Serie que é informada pelo usuario				³±±
±±³								 para realizar a conulta                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ cSerie - Caractere                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ ACDI011                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function ConsSerNf(tabela, cSerie, numero, cFornec, cLojaFor )

Local aSeries 	:= {}
Local OBROWSE 	:= Nil
Local aHeader		:= {}

aAdd(aHeader,{ STR0001, "F1_DOC",     '@!',  9,  , , , "C",,})
aAdd(aHeader,{ STR0002, "F1_SERIE",   '!!!', 14, , , , "C",,})
aAdd(aHeader,{ STR0067,"F1_EMISSAO",  '@!',  8,  , , , "D",,})

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


/*/{Protheus.doc} AWzVPt
	Funcao Responsavel por Validar o Codigo do Pallet Informado para Impressao
	@type  Static Function
	@author Paulo V. Beraldo
	@since Mai/2020
	@version 1.00
	@param cCodPt	, Caracter	, Codigo do Pallet que Sera Atualizado pela Funcao e Usado na Impressao
	@param oWizard	, Object	, Objeto Wizard Pai
	@param aParam	, Array		, Vetor com as Informacoes Referentes ao Item Escolhido em Tela Ex: Pallet
	@param nOrigem	, Integer	, Indica qual a Posicao do Vetor aParam esta sendo Executado
	@return lRet	, Boolean	, Retorno Logico que Indica se Pode Ou N?o Prosseguir com a Impressao da Etiqueta.
/*/
Static Function AWzVPt( cCodPt, oWizard, aParam, nOrigem )
Local lRet		:= .T.
Local aArea		:= GetArea()
Local aAreaCB0	:= CB0->( GetArea() )
Local cPallet	:= Nil

Default cCodPt	:= CriaVar( "CB0_PALLET", .F. )
cPallet	:= IIf ( Empty( cCodPt ), Padr( aParam[ nOrigem ][ 03 ][ 01 ], TamSx3( "CB0_PALLET" )[ 1 ] ), cCodPt )

dbSelectArea( "CB0" )
CB0->( dbSetOrder( 5 ) )

If Empty( cPallet )
  	MsgAlert( STR0068 , STR0042 ) //"Necessario Informar o Codigo do Pallet" | "Aviso"
  	lRet := .F.
Else
	If !CB0->( dbSeek( FWxFilial( "CB0") + cPallet ) )
		MsgAlert( STR0069 , STR0042 ) //"Codigo do Pallet Nao Encontrado" | "Aviso"
		lRet := .F.
	Else
		cCodPt 	 := CB0->CB0_PALLET
	EndIf               
EndIf

RestArea( aAreaCB0 )
RestArea( aArea )
Return lRet
