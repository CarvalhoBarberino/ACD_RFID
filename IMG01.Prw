#include 'TOTVS.CH'
#include 'RPTDEF.CH'
#include 'FWPrintSetup.ch'

/*/{Protheus.doc} IMG01
@author Sérgio Souza
@since 17/02/2023
@version P12
@description Impressão MIT044 FSC Forest
/*/


User Function IMG01()

	LOCAL _nIdx     := 0 as integer
	LOCAL _nCop     := 0 as integer
	LOCAL _cFont    := '020,020' as character
	LOCAL _cFont1   := '030,030' as character
	LOCAL _cFont2   := '050,050' as character

	LOCAL _lA4      := .T. as logical // marca se será folha A4

	DEFAULT COPCSEL := ""


	_nIdx := If( type('ParamIxb') = 'A',  val(Paramixb[ 5 ]), 0 )

	If COPCSEL == "Produto Avulso" /* A4 Bobinas  _nImp = 0 a4  _nImp = 1 sem wizard sx1 etiqueta endereçamento */

		For _nCop := 1 To _nIdx

			If Paramixb[ 1 ]

				If _lA4 .Or.;
						rTrim( CB5->CB5_MODELO ) == 'A4'

					ImprA4()

				Else

					MSCBChkStatus( .F. )
					MSCBBegin(1,6,50,.F.) /* Inicio da Imagem da Etiqueta */

					MSCBLoadGRF("FORESTPA.PCX")    /* carrega imagem transferida para a memória da impressora */
					MSCBGrafic(25,000, "FORESTPA") /* impressão da imagem */

					MSCBSay(005, 010, "Produto: " + rtrim(SB1->B1_DESC) ,'N','0',_cFont, .F.) /* Produto */
					MSCBSay(005, 013, "Lote: " + rtrim(Paramixb[ 7 ]) ,'N','0',_cFont, .F.) /* Produto */
					MSCBSAYBAR(005,016,Paramixb[ 7 ],'N','MB07',8,.F.,.F.,,'B',2.3,2)
					/*
					MSCBSay(005, 026, "g/m2: " + lTrim(TransForm(SB1->B1_XGRAMA,"@E 9999")) ,'N','0',_cFont, .F.) // g/m2
					MSCBSay(020, 026, "Largura x Comprimento: "+ lTrim(TransForm(SB1->B1_XLARG ,"@E 9999"))+ ' x ' + ltrim(TransForm(SB1->B1_XALT ,"@E 9999")) ,'N','0',_cFont, .F.) // Largura x Comprimento
					MSCBSay(005, 029, "FIBRA: "    + lTrim(TransForm(SB1->B1_XFIBRA ,PesqPict("SB1","B1_XFIBRA")))  ,'N','0',_cFont, .F.)  // Fibra
					MSCBSay(033, 029, "DIAMETRO: " + lTrim(TransForm(SB1->B1_XDIAMET,PesqPict("SB1","B1_XDIAMET"))) ,'N','0',_cFont, .F.)  // Diâmetro
					MSCBSay(055, 029, "TUBETE: "   + lTrim(TransForm(SB1->B1_XTUBETE,PesqPict("SB1","B1_XTUBETE"))) ,'N','0',_cFont, .F.)  // Tubete
					MSCBSay(005, 032, "QTD. FOLHAS : "+lTrim(TransForm(SB1->B1_XFOL,PesqPict("SB1","B1_XFOL"))) ,'N','0',_cFont, .F.)  // Qtd. Folhas
					*/
					MSCBSay(033, 032, "PESO LÍQ.(t): "+lTrim(TransForm(SB1->B1_PESO,PesqPict("SB1","B1_PESO"))) ,'N','0',_cFont, .F.) /* Peso Liq.*/
					MSCBSay(055, 032, "PESO BRUTO (t): "+lTrim(TransForm(SB1->B1_PESO,PesqPict("SB1","B1_PESO"))) ,'N','0',_cFont, .F.) /* Peso Bruto */

					//MSCBSAYBAR(005,042,SB1->B1_COD+Paramixb[ 7 ],'N','MB03',10,.F.,.T.,,'B',2.3,2)
					MSCBSAYBAR(005,036,SB1->B1_COD,'N','MB07',12,.F.,.F.,,'B',2.3,2) /* Code128 */
					//MSCBSay((100 - Len(rtrim(SB1->B1_COD))) / 2,045, rtrim(SB1->B1_COD) ,'N','0',_cFont, .F.) /* Código do Produto */

					//MSCBSay(030,050, rtrim(Paramixb[ 7 ]),  ,'N','0',_cFont, .F.) /* Lote */
					MSCBEnd()     /* Fim da Imagem da Etiqueta */

				End

			End

		Next

	ElseIf COPCSEL == 'Ordem de Producao' /* Revita Ambiental e Forest Paper */

		For _nCop := 1 To _nIdx

			If Paramixb[ 1 ]

				SB1->( MSSeek( FWxFilial('SB1') + Paramixb[ 2 ], .F.  ) ) /* Produto*/
				SC2->( DBGoTo( Paramixb[ 11 ] ) ) /* Ordem de Producao */
				SC5->( MSSeek( FWxFilial('SC5') + Paramixb[ 9 ]   , .F.  ) ) /* Pedido de Venda */
				SA1->( MSSeek( FWxFilial('SA1') + SC5->C5_CLIENTE + SC5->C5_LOJACLI  , .F.  ) ) /* Cliente */

				//MSCBPrinter("Z170XI", _cPorta, , 50 )   /* Seta tipo de impressora no padrao ZPL */

				MSCBChkStatus( .F. )
				MSCBBegin(1,6,50,.F.) /* Inicio da Imagem da Etiqueta */

				MSCBSay(005,010, 'Código Produto: ' + rtrim(SB1->B1_COD)  ,'N','0',_cFont, .F.)



				MSCBLoadGRF("FORESTPA.PCX")    /* carrega imagem transferida para a memória da impressora */
				MSCBGrafic(25,000, "FORESTPA") /* impressão da imagem */

				MSCBSay(005,013, 'Código Lote: ' + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN + if( ! empty(SC2->C2_OBS),"    ID Bobina: " + rTrim(SC2->C2_OBS), ""),'N','0',_cFont, .F.)
				MSCBSAYBAR(005,016,SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN,'N','MB07',8,.F.,.F.,,'B',2.3,2)

				MSCBLineH(005,025,80,2)

				MSCBSay(005,026, 'PEDIDO DE VENDA: ' + if(empty(SC5->C5_NUM)," ",SC5->C5_NUM) + '   ORDEM DE PRODUCAO: ' + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN,'N','0',_cFont, .F.)
				MSCBSay(005,029, 'CLIENTE: ' + if(empty(SA1->A1_NOME)," ",SA1->A1_NOME) ,'N','0',_cFont, .F.)
				MSCBSay(005,032, SB1->B1_DESC ,'N','0',_cFont, .F.)

				MSCBLineH(004,035,99,2)
				//MSCBSAYBAR(005,043,SB1->B1_COD + SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN,'N','MB02',9,.F.,.T.,,'B',2.3,2)
				//MSCBSAYBAR(005,035,{{"8003",SB1->B1_COD},{"23",Paramixb[ 7 ]+MSCB128B()+MSCB128C()}} /*SB1->B1_COD+Paramixb[ 7 ]*/,'N','MB07',10,.F.,.T.,,'B',2.3,2) // Padrão GS1
				MSCBSAYBAR(004,036,SB1->B1_COD,'N','MB07',12,.F.,.F.,,'B',2.3,2)

				MSCBEnd()     /* Fim da Imagem da Etiqueta */
				//MSCBClosePrinter() /* Finaliza conexão com impressora */

			End

		Next

	ElseIf COPCSEL = 'Nota Fiscal' /* Recebimento MP p/NF Revita, arquivo MIT044 - Etiquetas - Modelo 1 - Etiqueta de Recebimento e identificação MP */

		//MCB5SetImp(CBRLocImp(""),IsTelNet())

		For _nCop := 1 To _nIdx

			If Paramixb[ 1 ]

				If _lA4 .Or.;
						rTrim( CB5->CB5_MODELO ) = 'A4'

					ImprA4()

				Else

					SB1->( MSSeek( FWxFilial('SB1') + Paramixb[ 2 ], .F.  ))
					SD1->( dbGoTo( Paramixb[ 11 ] ) )

					MSCBChkStatus( .F. )
					MSCBBegin(1,6,50,.F.) /* Inicio da Imagem da Etiqueta */

					MSCBLoadGRF("FORESTPA.PCX")    /* carrega imagem transferida para a memória da impressora */
					MSCBGrafic(60,000,"FORESTPA") /* impressão da imagem */

					MSCBSay(004,008, 'Código do Produto: ' + rtrim(SB1->B1_COD)  ,"N","0",_cFont1,.F.)
					MSCBSay(004,011, 'Código Lote: ' + Paramixb[ 7 ] ,'N','0',_cFont1, .F.)
					MSCBSAYBAR(004,014,Paramixb[ 7 ],'N','MB07',8,.F.,.F.,,'B',2.3,2)

					If ! Empty(Paramixb[ 9 ])

						MSCBSay(075,026, Str(Val(ParamIxb[ 4 ]),4,0) + ' Kg' ,'N','0',_cFont2, .F.)

					End

					MSCBLineH(004,023,98,2)

					MSCBSay(004,024, 'NF: ' + rTrim(SF1->F1_DOC) + if(Empty(SF1->F1_SERIE),'','/') + rTrim(SF1->F1_SERIE) + if( ! empty(Paramixb[ 9 ]),"    ID Bobina: " + rTrim(Paramixb[ 9 ]), ""),"N","0",_cFont1,.F.)

					if ! empty(Paramixb[ 9 ])

						MSCBSay(004,027, 'Número de Peça(s): 1' ,"N","0",_cFont1,.F.)

					Else

						MSCBSay(004,027, 'Número de Fardo(s): '+ lTrim(TransForm(SD1->D1_XNFAR,PesqPict("SD1","D1_XNFAR"))) ,"N","0",_cFont1,.F.)

					End
					MSCBSay(004,030, rtrim(SB1->B1_DESC) ,"N","0",_cFont1,.F.)

					MSCBLineH(004,033,98,2)

					//MSCBSAYBAR(005,035,{{"8003",SB1->B1_COD},{"23",Paramixb[ 7 ]+MSCB128B()}} /*SB1->B1_COD+Paramixb[ 7 ]*/,'N','MB07',10,.F.,.T.,,'B',2.3,2,.T.)
					MSCBSAYBAR(004,034,SB1->B1_COD,'N','MB07',12,.F.,.F.,,'B',2.3,2)

					MSCBEnd()     // Fim da Imagem da Etiqueta

				End

			End

		Next

		//MscbClosePrinter() // Finaliza conexão com impressora

	End

	If type('_nPnt') == 'N' .And. _nIdx <> 0

		aLbx[ _nPnt ][ 1 ] := .F.

	End

Return( NIL )

Static Function ImprA4()

	//LOCAL oFont8   := TFont():New('Arial',9,14,,.F.,,,,.T.,.F.)
	LOCAL oFont15n := TFont():New('Arial',9,22,,.T.,,,,.T.,.F.)
	LOCAL oFont15  := TFont():New('Arial',9,22,,.F.,,,,.T.,.F.)
	LOCAL oFont18  := TFont():New('Arial',18,35,,.F.,,,,.T.,.F.)

	aLbx[ _nPnt ][ 1 ] := .F.
	SB1->( MSSeek( FWxFilial('SB1') + Paramixb[ 2 ], .F.  ))

	cNomeRel := rtrim( Paramixb[ 2 ] ) + if( ! empty(Paramixb[ 9 ]), rTrim(Paramixb[ 9 ]),"")
	oPrint := FWMsPrinter():New( cNomeRel, IMP_PDF, .T.,,.F.) // Inicia o relatório

	If type('oPrint:ofilewriter') <> "U"

		oPrint:nqtdcopies := val(Paramixb[ 5 ] )
		oPrint:StartPage()

	Else

		FreeObj( oPrint )
		oPrint := NIL
		Return( NIL )

	End

/*
   Montagem de cabeçalho, caso a impressão ocorra via A4 em branco

   oPrint:SayBitmap(10,450,'\system\ForestPaperLP.Png',1600,340)
   oPrint:SayBitmap(100,150,'\system\mistoforest.jpg' , 285,400)
   oPrint:QRCode( 450, 1970 , 'https://l.ead.me/bcqpLO', 75 ) 

   oPrint:Say(300,600, 'FOREST PAPER INDUSTRIA E COMERCIO DE PAPEL LTDA', oFont15n)
   oPrint:Say(340,600, 'CNPJ 07.0155.032/0001-05     IE: 903.367.41-52' , oFont15n)

   oPrint:Line( 373, 600, 373, 1875 )

   oPrint:Say(420,600, 'Escritório São Paulo'          , oFont8n,,CLR_BLACK)
   oPrint:Say(420,1200, 'Unidade Fabril Telêmaco Borba', oFont8n,,CLR_BLACK)

   oPrint:Say(440,600, 'Rua Gomes de Carvalho, 1069, Cj 123/124', oFont8)
   oPrint:Say(440,1200, 'Rodovia do Papel PR-160,855 - KM 21'    , oFont8)

   oPrint:Say(470,600, 'Vila Olimpia | São Paulo | Brasil'                        , oFont8)

   oPrint:Say(470,1200, 'Parque Limeira área 7 | Telêmaco Borba - PR | Brasil'     , oFont8)

   oPrint:Say(500,600, 'CEP: 04547-004', oFont8)
   oPrint:Say(500,1200, 'CEP: 84269-000', oFont8)

   oPrint:Say(530,600, 'Fone: +55 (11) 2925-0961', oFont8)
   oPrint:Say(530,1200, 'Fone: +55 (11) 3271-8100', oFont8)

   oPrint:Say(550,160, 'Procure por nossos produdos', oFont6n)

   oPrint:Say(570,240, 'certificados FSC',oFont6n)

   //oPrint:Line( 600, 010, 1800, 2000 )

*/

	//oPrint:Say( 1450, 300, rtrim(substr(SB1->B1_COD,1,at(SB1->B1_COD,lTrim(TransForm(SB1->B1_XGRAMA,"@E 9999"))))) , oFont18) /* Código Produto */
	oPrint:Say( 1450, 300, rtrim(SB1->B1_DESC) , oFont18) /* Produto Descrição*/
	//oPrint:Say( 1450, 950, lTrim(TransForm(SB1->B1_XGRAMA,"@E 9999"/*PesqPict("SB1","B1_XGRAMA")*/)) , oFont18) /* g/m2 */
	//oPrint:Say( 1450,1550, lTrim(TransForm(SB1->B1_XLARG ,"@E 9999"/*PesqPict("SB1","B1_XLARG")*/))+ ' x ' + ltrim(TransForm(SB1->B1_XALT ,"@E 9999"/*PesqPict("SB1","B1_XALT")*/)), oFont18) /* Largura x Comprimento */

	/*
	oPrint:Say( 1830, 350, lTrim(TransForm(SB1->B1_XFIBRA ,PesqPict("SB1","B1_XFIBRA"))) , oFont18)  // Fibra
	oPrint:Say( 1830, 980, lTrim(TransForm(SB1->B1_XDIAMET,PesqPict("SB1","B1_XDIAMET"))), oFont18)  // Diâmetro
	oPrint:Say( 1830,1730, lTrim(TransForm(SB1->B1_XTUBETE,PesqPict("SB1","B1_XTUBETE"))), oFont18)  // Tubete
	*/

	If COPCSEL <> 'Nota Fiscal'

		//oPrint:Say(2310, 350, lTrim(TransForm(SB1->B1_XFOL,"@E 9999"/*PesqPict("SB1","B1_XFOL")*/)), oFont18)  /* Qtd. Folhas */
		oPrint:Say(2310, 980, lTrim(TransForm(SB1->B1_PESO,PesqPict("SB1","B1_PESO"))), oFont18) /* Peso Liq.*/

	End

	oPrint:Say(2310,1730, lTrim(TransForm(Val(ParamIxb[ 4 ]),PesqPict("SB1","B1_PESO")))+" "+SB1->B1_UM, oFont18) /* Peso Bruto */
	oPrint:Say(2520,510, Space( 40 - len(if( ! empty(Paramixb[ 9 ]),"ID Bobina " + rTrim(Paramixb[ 9 ]), ""))) + if( ! empty(Paramixb[ 9 ]),"ID Bobina " + rTrim(Paramixb[ 9 ]), ""), oFont15n)
	oPrint:Say(2620,510, Space( 40 - len(rtrim(SB1->B1_COD))) + rtrim(SB1->B1_COD), oFont15n) /* Código do Produto */

	oPrint:Code128(2635,510,SB1->B1_COD  , 0.73, 30, .F.)
	oPrint:Code128(2775,510,Paramixb[ 7 ], 0.73, 30, .F.)

	oPrint:Say(2900,510, Space( 40 - len(rtrim(Paramixb[ 7 ]))) + rtrim(Paramixb[ 7 ]), oFont15) /* Lote */

	oPrint:EndPage() // Finaliza a página

	oPrint:Print()

	FreeObj( oPrint )
	oPrint := NIL

Return( NIL )

