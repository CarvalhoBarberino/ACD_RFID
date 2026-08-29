#INCLUDE "protheus.ch"
#INCLUDE "RWMAKE.CH"

#DEFINE NOME_FONTE		"NEXACD.PRW"

#DEFINE ORACLE

/*/{Protheus.doc} aptProd
Funcao faz apontamento de producao. Eh chamado pelo webservice nexSolucoes
@type user function
@author Julio Carvalho Barberino
@since 09/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function aptProd(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local aVetor
	local aRet				:= {.F., "Erro: O apontamento de produção não terminou"}
	local nOpc				:= 3

	aVetor := {;
		{"D3_OP",			cOp,								NIL},;
		{"D3_TM",			superGetMV("SU_TMAPT", .F.),		NIL},;
		{"D3_COD",			cCodProd,							NIL},;
		{"D3_DESCRI",		cDescr,								NIL},;
		{"D3_LOCAL",		cArmazem,							NIL},;
		{"D3_LOTECTL",		cLote,								NIL},;
		{"D3_QUANT",		nQuant,								NIL},;
		{"D3_ZB0COD",		cTags,								NIL};
		}

	lMsErroAuto		:= .F.
	MSExecAuto({|x, y| mata250(x, y)}, aVetor, nOpc)

	if lMsErroAuto
		aRet[1] := .F.
		aRet[2] := mostraErro("\temp\erro.txt")
		return aRet
	endIf

	aRet := {.T., "gravou Ok"}
return aRet

/*/{Protheus.doc} endereca
Funcao faz enderecamento lotes recem produzidos. Eh chamado pelo webservice nexSolucoes
@type user function
@author Julio Carvalho Barberino
@since 10/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function endereca(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local oArea				:= fwGetArea()
	local aRet				:= {.F., "Erro: O endereçamento não terminou"}
	local cQy				:= ""
	local cAliasD3			:= getNextAlias()
	local cNumseq
	local aItensSDB			:= {}
	local aCabSDA
	local aItSDB
	local cAptEnd			:= superGetMV("NX_APTEND", .F., "APT")
	private lMsErroAuto

	if "N" == posicione("SB1", 1, cFilia + cCodProd, "B1_LOCALIZ") // B1_FILIAL + B1_COD
		aRet[1] := .T.
		aRet[2] := "não endereçar"
		fwRestArea(oArea)
		return aRet
	endIf

	#IFDEF ORACLE
		cQy += "SELECT " + CRLF
	#ELSE
		cQy += "SELECT TOP 1 " + CRLF
	#ENDIF
	cQy += "	D3_NUMSEQ " + CRLF
	cQy += "FROM " + CRLF
	cQy += "	" + retSqlName("SD3") + " " + CRLF
	cQy += "WHERE " + CRLF
	cQy += "	D3_FILIAL = '" + cFilia + "' " + CRLF
	cQy += "	AND D3_OP = '" + cOp + "' " + CRLF
	cQy += "	AND D3_COD = '" + cCodProd + "' " + CRLF
	cQy += "	AND D3_LOCAL = '" + cArmazem + "' " + CRLF
	cQy += "	AND D3_CF = 'PR0' " + CRLF
	cQy += "ORDER BY " + CRLF
	cQy += "	R_E_C_N_O_ DESC "
	#IFDEF ORACLE
		cQy += "FETCH FIRST 1 ROW ONLY " + CRLF
	#ENDIF
	dbUseArea(.T., "TOPCONN", TCGenQry(, , cQy), cAliasD3, .T., .T.)
	dbSelectArea(cAliasD3)
	(cAliasD3)->(dbGoTop())
	cNumseq := alltrim((cAliasD3)->D3_NUMSEQ)
	(cAliasD3)->(dbCloseArea())

	//Cabecalho com a informação do item e NumSeq que sera endereçado.
	aCabSDA := {;
		{"DA_PRODUTO",		cCodProd,		Nil},;
		{"DA_NUMSEQ",		cNumseq,		Nil};
		}
	//Dados do item que será endereçado
	aItSDB := {;
		{"DB_ITEM",			"0001",			Nil},;
		{"DB_ESTORNO",		" ",			Nil},;
		{"DB_LOCALIZ",		cAptEnd,		Nil},;
		{"DB_DATA",			dDataBase,		Nil},;
		{"DB_NUMSERI",		cSerie,			Nil},;
		{"DB_QUANT",		nQuant,			Nil},;
		{"DB_ZB0COD",		cTags,			Nil};
		}
	aadd(aItensSDB,aitSDB)
	//Executa o endere?amento do item
	lMsErroAuto := .F.
	MATA265(aCabSDA, aItensSDB, 3) // Necessita declara antes (lá em cima) private lMsErroAuto
	if lMsErroAuto
		aRet[1] := .F.
		aRet[2] := mostraErro("\temp\erro.txt")
		fwRestArea(oArea)
		return aRet
	endIf

	aRet[1] := .T.
	aRet[2] := "gravou Ok" // posicione("SDB", 1, cFilia + padR(cCodProd, tamSx3("DB_PRODUTO")[1], " ") + cArmazem + cNumseq + cOp, "DB_LOCALIZ") // DB_FILIAL + DB_PRODUTO + DB_LOCAL + DB_NUMSEQ + DB_DOC
	fwRestArea(oArea)
return aRet

/*/{Protheus.doc} criarZB0
Funcao registra dados na tabela ZB0. Eh chamado no ponto de entrada MTA265I
@type user function
@author Julio Carvalho Barberino
@since 20/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function criarZB0(aDadosZB0)
/*
Exemplo de vetor que a função espera receber:
	{;
		{"ZB0_CODETI",		SDB->DB_ZB0COD}, ;
		{"ZB0_DTNASC",		date()}, ;
		{"ZB0_TIPO",		"01"}, ;
		{"ZB0_CODPRO",		SDB->DB_PRODUTO}, ;
		{"ZB0_DESPRO",		posicione("SB1", 1, fwXFilial("SB1") + SDB->DB_PRODUTO, "B1_DESC")}, ;
		{"ZB0_QTDE",		SDB->DB_QUANT}, ;
		{"ZB0_LOCAL",		SDB->DB_LOCAL}, ;
		{"ZB0_LOCALI",		SDB->DB_LOCALIZ}, ;
		{"ZB0_LOTE",		SDB->DB_LOTECTL}, ;
		{"ZB0_SLOTE",		SDB->DB_NUMLOTE}, ;
		{"ZB0_OP",			SDB->DB_DOC}, ;
		{"ZB0_NUMSEQ",		SDB->DB_NUMSEQ}, ;
		{"ZB0_NUMSER",		SDB->DB_NUMSERI} ;
	}
*/

	local nI
	local cTipoEsperado
	local cTipoRecebido
	local lTipoIgual
	local lTamanhoOk
	local cNumDisponivel	:= ""
	local oArea				:= fwGetArea()

	if valType(aDadosZB0) <> "A"
		return .F.
	endIf

	dbSelectArea('ZB0')
	ZB0->(dbSetOrder(1))

	/*
	While .T.
		cNumDisponivel := Padr(CBProxCod('MV_CODZB0'),10)
		If !ZB0->(DbSeek(xFilial("ZB0")+cNumDisponivel))
			msgAlert("Numero disponivel para gravação: " + cNumDisponivel, NOME_FONTE + " informa")
			exit
		endIf
	EndDo
	*/

	recLock('ZB0',.T.)
	for nI := 1 to len(aDadosZB0)
		cTipoEsperado := tamSx3(aDadosZB0[nI][1])[3]
		cTipoRecebido := valType(aDadosZB0[nI][2])
		lTipoIgual := (cTipoRecebido == cTipoEsperado)
		lTamanhoOk := iif(cTipoRecebido == "C", len(aDadosZB0[nI][2]) <= tamSx3(aDadosZB0[nI][1])[1], .T.)
		If lTipoIgual .and. lTamanhoOk
			ZB0->&(aDadosZB0[nI][1]) := aDadosZB0[nI][2]
		endIf
	next
	msUnLock()
	fwRestArea(oArea)
return cNumDisponivel

/*/{Protheus.doc} MTA265I
Ponto de entrada chamado durante o enderecamento https://tdn.totvs.com/pages/releaseview.action?pageId=6087816
@type user function
@author Julio Carvalho Barberino
@since 09/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function MTA265I()
	local aDadosZB0
	local oArea
	if !empty(allTrim(SDB->DB_ZB0COD))
		oArea := fwGetArea()
		aDadosZB0 := {;
			{"ZB0_CODETI",		SDB->DB_ZB0COD}, ;
			{"ZB0_DTNASC",		date()}, ;
			{"ZB0_TIPO",		"01"}, ;
			{"ZB0_CODPRO",		SDB->DB_PRODUTO}, ;
			{"ZB0_DESPRO",		posicione("SB1", 1, fwXFilial("SB1") + SDB->DB_PRODUTO, "B1_DESC")}, ;
			{"ZB0_QTDE",		SDB->DB_QUANT}, ;
			{"ZB0_LOCAL",		SDB->DB_LOCAL}, ;
			{"ZB0_LOTE",		SDB->DB_LOTECTL}, ;
			{"ZB0_SLOTE",		SDB->DB_NUMLOTE}, ;
			{"ZB0_OP",			left(SDB->DB_DOC, 11)}, ;
			{"ZB0_NUMSEQ",		SDB->DB_NUMSEQ}, ;
			{"ZB0_NUMSER",		SDB->DB_NUMSERI} ;
			}

		U_criarZB0(aDadosZB0)
		fwRestArea(oArea)
	endIf
return

/*/{Protheus.doc} CBRETEAN
Ponto de entrada chamado quando faz leitura do codigo de barras no coletor https://tdn.totvs.com/pages/releaseview.action?pageId=6091038
@type user function
@author Julio Carvalho Barberino
@since 14/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function CBRETEAN()
	local oArea				:= fwGetArea()
	local cId				:= padR(paramIXB[1], tamSX3("ZB0_CODETI")[1])
	local aRet				:= {}

	dbSelectArea('ZB0')
	ZB0->(dbSetOrder(1))
	if ZB0->(msSeek(fwXFilial('ZB0') + cId))
		aRet := {;
			ZB0->ZB0_CODPRO, ;
			ZB0->ZB0_QTDE, ;
			ZB0->ZB0_LOTE, ;
			NIL, ;
			ZB0->ZB0_NUMSER, ;
			NIL;
			}
	endIf

	fwRestArea(oArea)
return aRet // Espera devolver aRet = {"Código do Produto","Quantidade(Embalagem normalmente analisado na nQE := SB1->B1_QE no processo padrão)","Lote","Data de Validade","Número de Série","Endereço Destino"}

/*/{Protheus.doc} MTA650MNU
Ponto de entrada chamado no carregamento de opcoes da rotina Ordem de Producao https://tdn.totvs.com/display/public/PROT/MTA650MNU
@type user function
@author Julio Carvalho Barberino
@since 20/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function MTA650MNU()
/*
Estrutura do vetor aRotina:
[1]Nome a aparecer no cabecalho
[2]Nome da Rotina associada
[3]Reservado
[4]Tipo de Transação a ser efetuada, podendo conter:
1 - Pesquisa e Posiciona em um Banco de Dados
2 - Simplesmente Mostra os Campos
3 - Inclui registros no Bancos de Dados
4 - Altera o registro corrente
5 - Remove o registro corrente do Banco de Dados
[5]Nivel de acesso
[6]Habilita Menu Funcional
*/
	aAdd(aRotina, {'Envia Op p/ SEGEL', 'U_opToSegel()', 0, 4 })
return

/*/{Protheus.doc} opToSegel
Rotina que envia ordem de produção para o end point da SEGEL
@type user function
@author Julio Carvalho Barberino
@since 20/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function opToSegel()
	local oArea			:= fwGetArea()
	local aHeader		:= {}
	local cCodProd		:= allTrim(SC2->C2_PRODUTO)
	local cOp			:= allTrim(SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
	local cUrl			:= "http://192.168.0.3:8000" // juk usar parametros
	local cPath			:= "/api/production_order" // juk usar parametros
	local lRetOk
	local oRestClient	:= FWRest():New(cUrl) // https://tdn.totvs.com/display/public/framework/FWRest
	local OJson0		:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local cRet			:= ""

	dbSelectArea("SB1")
	SB1->(dbSetOrder(1)) // B1_FILIAL + B1_COD

	if !SB1->(msSeek(fwXFilial("SB1") + cCodProd))
		msgAlert("Produto " + cCodProd + " não cadastrado na filial " + fwXFilial("SB1") + ".", NOME_FONTE)
		return
	endIf

	if "PA" != SB1->B1_TIPO
		msgAlert("Não é permitido enviar OP para SEGEL quando o produto não for do tipo PA.", NOME_FONTE)
		return
	endIf

	if "S" == SC2->C2_ZOPENV
		msgAlert("OP já foi enviada para a SEGEL", NOME_FONTE)
		return
	endIf

	if !msgYesNo("Confirma envio da OP " + cOp + "?" + CRLF + "Produto: " + cCodProd + CRLF + "Descrição: " + allTrim(SB1->B1_DESC) + CRLF + "Quantidade: " + cValToChar(SC2->C2_QUANT) + " " + SC2->C2_UM, NOME_FONTE)
		msgAlert("Abortado pelo operador", NOME_FONTE)
		return
	endIf

/*	Exemplo de json que deve ser enviado
	{
		"filial": "01",
		"op": "AABV8801001",
		"cod_prod": "XXXXXX",
		"descricao": "SUENOLAR SUPER DORMILAR  111 X 222",
		"local": "01",
		"lote": "AABV8801001", é o proprio numero da ordem
		"qtd": 10,
		"familia": "ASP"
	}
*/
	OJson0["filial"] := SC2->C2_FILIAL
	OJson0["op"] := cOp
	OJson0["cod_prod"] := cCodProd
	OJson0["descricao"] := allTrim(SB1->B1_DESC)
	OJson0["local"] := SC2->C2_LOCAL
	OJson0["lote"] := cOp
	OJson0["qtd"] := SC2->C2_QUANT
	OJson0["familia"] := allTrim(SB1->B1_MARCA) + allTrim(SB1->B1_FAMILY)

	cJson0 := OJson0:ToJson()
	showLog(cJson0)
	Aadd(aHeader, "Content-Type: application/json")
	Aadd(aHeader, "Authorization: Basic " + encode64(superGetMV("SU_USRSEGE", .T., "SuperEu") + ":" + superGetMV("SU_PSWSEGE", .T., "Teste@123")))
	showLog(VarInfo("aHeader", aHeader, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	//Aadd(aHeader, "Authorization: Basic b3BlcmFkb3JAY2xpZW50ZS5jb206cGFzc3dvcmQ=")
	//Aadd(aHeader, "Authorization: Basic " + Encode64("app01:fTdUlDgdQQ4MRQhLahykiKhON6k97Zfly5SV6fwpa5zCE"))
	oRestClient:SetPath(cPath)
	oRestClient:SetPostParams(cJson0)

	lRetOk := oRestClient:post(aHeader)
	if lRetOk
		cRet += oRestClient:getResult()
		recLock("SC9", .F.)
		SC2->C2_ZOPENV := "S"
		msUnLock()
	else
		cRet += "ERRO" + CRLF + oRestClient:getLastError() + CRLF + oRestClient:getResult()
	endIf

	showLog(cRet) // juk Continuar daqui. Precisa decidir o que fazer com a informação de retorno. Precisa criar campo na SC2 pra guardar o retorno

	fwRestArea(oArea)
return

/*/{Protheus.doc} C9DrivIn
Efetua o cálculo da área de alguns quadriláteros.
@type user function
@author Julio Carvalho Barberino
@since 20/07/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function C9DrivIn()
	local cPedidoDe
	local cPedidoAte
	local cCliDe
	local cCliAte
	local cLojaDe
	local cLojaAte
	local dDataDe
	local dDataAte
	local cProdDe
	local cProdAte
	local cQy				:= ""
	local cAliasC9			:= getNextAlias()
	local cAliasTemp
	local nTamIdx			:= tamSX3("C5_FECENT")[1] + tamSX3("C9_CLIENTE")[1] + tamSX3("C9_PEDIDO")[1] + tamSX3("C9_ITEM")[1] + tamSX3("C9_SEQUEN")[1]
	local aEstrutura		:= {;
		{"C9_FILIAL",		"Filial",			tamSX3("C9_FILIAL")[3],			tamSX3("C9_FILIAL")[1],			tamSX3("C9_FILIAL")[2],		""},;
		{"C9_PEDIDO",		"Pedido",			tamSX3("C9_PEDIDO")[3],			tamSX3("C9_PEDIDO")[1],			tamSX3("C9_PEDIDO")[2],		""},;
		{"C9_CLIENTE",		"Cliente",			tamSX3("C9_CLIENTE")[3],		tamSX3("C9_CLIENTE")[1],		tamSX3("C9_CLIENTE")[2],	""},;
		{"C9_LOJA",			"Loja",				tamSX3("C9_LOJA")[3],			tamSX3("C9_LOJA")[1],			tamSX3("C9_LOJA")[2],		""},;
		{"A1_NOME",			"Cli Nome",			tamSX3("A1_NOME")[3],			tamSX3("A1_NOME")[1],			tamSX3("A1_NOME")[2],		""},;
		{"C9_DATENT",		"Entrega",			tamSX3("C9_DATENT")[3],			tamSX3("C9_DATENT")[1],			tamSX3("C9_DATENT")[2],		""},;
		{"C9_ITEM",			"Item",				tamSX3("C9_ITEM")[3],			tamSX3("C9_ITEM")[1],			tamSX3("C9_ITEM")[2],		""},;
		{"C9_SEQUEN",		"Sequencia",		tamSX3("C9_SEQUEN")[3],			tamSX3("C9_SEQUEN")[1],			tamSX3("C9_SEQUEN")[2],		""},;
		{"C9_PRODUTO",		"Produto",			tamSX3("C9_PRODUTO")[3],		tamSX3("C9_PRODUTO")[1],		tamSX3("C9_PRODUTO")[2],	""},;
		{"B1_DESC",			"Descrição",		tamSX3("B1_DESC")[3],			tamSX3("B1_DESC")[1],			tamSX3("B1_DESC")[2],		""},;
		{"C9_LOCAL",		"Armazém",			tamSX3("C9_LOCAL")[3],			tamSX3("C9_LOCAL")[1],			tamSX3("C9_LOCAL")[2],		""},;
		{"C9_LOTECTL",		"Lote",				tamSX3("C9_LOTECTL")[3],		tamSX3("C9_LOTECTL")[1],		tamSX3("C9_LOTECTL")[2],	""},;
		{"PRD_ENDERE",		"Prod Endereço",	tamSX3("DC_LOCALIZ")[3],		tamSX3("DC_LOCALIZ")[1],		tamSX3("DC_LOCALIZ")[2],	""},;
		{"CLI_ENDERE",		"Cli Endereço",		tamSX3("A1_ENDREC")[3],			tamSX3("A1_ENDREC")[1],			tamSX3("A1_ENDREC")[2],		""},;
		{"NUMSERI",			"Num Serie",		tamSX3("C9_NUMSERI")[3],		tamSX3("C9_NUMSERI")[1],		tamSX3("C9_NUMSERI")[2],	""},;
		{"C9_QTDLIB",		"Quant. Lib",		tamSX3("C9_QTDLIB")[3],			tamSX3("C9_QTDLIB")[1],			tamSX3("C9_QTDLIB")[2],		""},;
		{"A1_MUN",			"Ciudad",			tamSX3("A1_MUN")[3],			tamSX3("A1_MUN")[1],			tamSX3("A1_MUN")[2],		""},;
		{"YA_DESCR",		"Pais",				tamSX3("YA_DESCR")[3],			tamSX3("YA_DESCR")[1],			tamSX3("YA_DESCR")[2],		""},;
		{"VOLUME",			"Volume",			tamSX3("B1_M3")[3],				tamSX3("B1_M3")[1],				tamSX3("B1_M3")[2],			""},;
		{"COMUNIC",			"Com. Status",		"N",							2,								0,							""},;
		{"REC",				"Rec",				"C",							nTamIdx,						0,							""},;
		{"SEL_OK",			"Sel",				"C",							2,								0,							""}}
	//	 Campo				Título				Típo						Tamanho						Decimais					Mascara
	local cCampoIdx			:= "REC"
	local cCampoSel			:= "SEL_OK"
	local oObjeto1
	local nIx


	if !Pergunte("C9DRIVEIN ", .T.)
		msgAlert("As perguntas não foram carregadas corretamente", NOME_FONTE)
		return
	endIf

	cPedidoDe	:= MV_PAR01
	cPedidoAte	:= MV_PAR02
	cCliDe		:= MV_PAR03
	cLojaDe		:= MV_PAR04
	cCliAte		:= MV_PAR05
	cLojaAte	:= MV_PAR06
	dDataDe		:= MV_PAR07
	dDataAte	:= MV_PAR08
	cProdDe		:= MV_PAR09
	cProdAte	:= MV_PAR10

	cQy := "SELECT " + CRLF
	cQy += "	C9_FILIAL, " + CRLF
	cQy += "	C9_PEDIDO, " + CRLF
	cQy += "	C9_CLIENTE, " + CRLF
	cQy += "	C9_LOJA, " + CRLF
	cQy += "	A1_NOME, " + CRLF
	cQy += "	C9_DATENT, " + CRLF
	cQy += "	C9_ITEM, " + CRLF
	cQy += "	C9_SEQUEN, " + CRLF
	cQy += "	C9_PRODUTO, " + CRLF
	cQy += "	B1_DESC, " + CRLF
	cQy += "	C9_LOCAL, " + CRLF
	cQy += "	C9_LOTECTL, " + CRLF
	cQy += "	COALESCE(DC_LOCALIZ, '') AS PRD_ENDERE, " + CRLF
	cQy += "	A1_END AS CLI_ENDERE, " + CRLF
	cQy += "	A1_MUN, " + CRLF
	cQy += "	YA_DESCR, " + CRLF
	cQy += "	CASE " + CRLF
	cQy += "		WHEN TRIM(C9_NUMSERI) = '' THEN DC_NUMSERI ELSE C9_NUMSERI " + CRLF
	cQy += "	END AS NUMSERI, " + CRLF
	cQy += "	C9_QTDLIB, " + CRLF
	cQy += "	C9_QTDLIB * B1_M3 AS VOLUME, " + CRLF
	cQy += "	CASE " + CRLF
	cQy += "		WHEN C9_ZCENARI = '' AND C9_ZDRIVIN IS NULL THEN 1 " + CRLF
	cQy += "		WHEN C9_ZCENARI <> '' AND C9_ZDRIVIN IS NULL THEN 2 " + CRLF
	cQy += "		WHEN C9_ZCENARI <> '' AND C9_ZDRIVIN IS NOT NULL THEN 2 " + CRLF
	cQy += "		WHEN C9_ZCENARI = '' AND C9_ZDRIVIN IS NOT NULL THEN 4 " + CRLF
	cQy += "	END AS COMUNIC, " + CRLF
	#IFDEF ORACLE
		cQy += "	C9_DATENT || C9_CLIENTE || C9_PEDIDO || C9_ITEM || C9_SEQUEN AS REC, " + CRLF
	#ELSE
		cQy += "	C9_DATENT + C9_CLIENTE + C9_PEDIDO + C9_ITEM + C9_SEQUEN AS REC, " + CRLF
	#ENDIF
	cQy += "	'' AS SEL_OK " + CRLF
	cQy += "FROM " + CRLF
	cQy += "	" + retSqlName("SC9") + " C9 " + CRLF
	cQy += "	INNER JOIN " + CRLF
	cQy += "		" + retSqlName("SC5") + " C5 " + CRLF
	cQy += "		ON " + fwJoinFilial("SC9", "SC5", "C9", "C5", .T., , .T.) + " " + CRLF // https://tdn.totvs.com/display/public/framework/FWJoinFilial
	cQy += "		AND C9_PEDIDO = C5_NUM " + CRLF
	cQy += "		AND C5.D_E_L_E_T_ = '' " + CRLF
	cQy += "	INNER JOIN " + CRLF
	cQy += "		" + retSqlName("SB1") + " B1 " + CRLF
	cQy += "		ON " + fwJoinFilial("SC9", "SB1", "C9", "B1", .T., , .T.) + " " + CRLF // https://tdn.totvs.com/display/public/framework/FWJoinFilial
	cQy += "		AND B1_COD = C9_PRODUTO " + CRLF
	cQy += "		AND B1.D_E_L_E_T_ = '' " + CRLF
	cQy += "	INNER JOIN " + CRLF
	cQy += "		" + retSqlName("SA1") + " A1 " + CRLF
	cQy += "		ON " + fwJoinFilial("SC9", "SA1", "C9", "A1", .T., , .T.) + " " + CRLF
	cQy += "		AND A1_COD = C9_CLIENTE " + CRLF
	cQy += "		AND A1.D_E_L_E_T_ = '' " + CRLF
	cQy += "	INNER JOIN " + CRLF
	cQy += "		" + retSqlName("SYA") + " YA " + CRLF
	cQy += "		ON " + fwJoinFilial("SC9", "SYA", "C9", "YA", .T., , .T.) + " " + CRLF
	cQy += "		AND YA_CODGI = A1_PAIS " + CRLF
	cQy += "		AND YA.D_E_L_E_T_ = '' " + CRLF
	cQy += "	LEFT JOIN " + CRLF
	cQy += "		" + retSqlName("SDC") + " DC " + CRLF
	cQy += "		ON " + fwJoinFilial("SC9", "SDC", "C9", "DC", .T., , .T.) + " " + CRLF
	cQy += "		AND DC_PRODUTO = C9_PRODUTO " + CRLF
	cQy += "		AND C9_LOCAL = DC_LOCAL " + CRLF
	cQy += "		AND DC_ORIGEM = 'SC6' " + CRLF
	cQy += "		AND DC_PEDIDO = C9_PEDIDO " + CRLF
	cQy += "		AND DC_ITEM = C9_ITEM " + CRLF
	cQy += "		AND DC_SEQ = C9_SEQUEN " + CRLF
	cQy += "		AND DC_LOTECTL = C9_LOTECTL " + CRLF
	cQy += "		AND DC_NUMLOTE = C9_NUMLOTE " + CRLF
	cQy += "		AND DC.D_E_L_E_T_ = '' " + CRLF
	cQy += "WHERE " + CRLF
	cQy += "	C9_FILIAL = '" + allTrim(fwXFilial("SC9")) + "' " + CRLF
	cQy += "	AND C9_PEDIDO BETWEEN '" + allTrim(cPedidoDe) + "' AND '" + allTrim(cPedidoAte) + "' " + CRLF
	cQy += "	AND C9_CLIENTE BETWEEN '" + allTrim(cCliDe) + "' AND '" + allTrim(cCliAte) + "' " + CRLF
	cQy += "	AND C9_LOJA BETWEEN '" + allTrim(cLojaDe) + "' AND '" + allTrim(cLojaAte) + "' " + CRLF
	cQy += "	AND C9_DATENT BETWEEN '" + allTrim(dToS(dDataDe)) + "' AND '" + allTrim(dToS(dDataAte)) + "' " + CRLF
	cQy += "	AND C9_PRODUTO BETWEEN '" + allTrim(cProdDe) + "' AND '" + allTrim(cProdAte) + "' " + CRLF
	cQy += "	AND C9_BLEST = '' " + CRLF
	cQy += "	AND C9_BLCRED = '' " + CRLF
	cQy += "	AND C9.D_E_L_E_T_ = '' " + CRLF
	cQy += "ORDER BY " + CRLF
	cQy += "	C9_PEDIDO, " + CRLF
	cQy += "	C9_ITEM, " + CRLF
	cQy += "	C9_SEQUEN"
	showLog(cQy)
	cQy := ChangeQuery(cQy)
	showLog(cQy)

	dbUseArea(.T., "TOPCONN", TCGenQry(, , cQy), cAliasC9, .F., .T.)
	dbSelectArea(cAliasC9)
	(cAliasC9)->(dbGoTop())

	oObjeto1 := jukMarkBrowse():New(aEstrutura, cAliasC9, cCampoIdx, cCampoSel)
	cAliasTemp := oObjeto1:getAliasTemp()
	oObjeto1:setARotina({;
		{"Enviar p/ DriveIn",	'U_goDrvIn("' + cAliasTemp + '")',			2,		0}, ;
		{"Inspecionar erro",	'U_inspGoDrvI("' + cAliasTemp + '")',		2,		0}})
	oObjeto1:jukPlay("Liberações a enviar para DrivIn")
return

/*/{Protheus.doc} inspGoDrvI
Mostra motivo do erro durante a comunicação do Protheus com o Drivin
@type user function
@author Julio Carvalho Barberino
@since 06/08/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function inspGoDrvI(cAliasTemp)

	dbSelectArea("SC9")
	SC9->(dbSetOrder(1))
	if !SC9->(msSeek(fwXFilial('SC9') + (cAliasTemp)->C9_PEDIDO + (cAliasTemp)->C9_ITEM + (cAliasTemp)->C9_SEQUEN + (cAliasTemp)->C9_PRODUTO + "  " + "  ")) // C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN + C9_PRODUTO + C9_BLEST + C9_BLCRED
		msgAlert("Erro de posicionamento na tabela SC9", NOME_FONTE)
		return
	endIf

	showLog(SC9->C9_ZDRIVIN)
return

/*/{Protheus.doc} goDrvIn
Envia os pedidos selecionados para o Drivin
@type user function
@author Julio Carvalho Barberino
@since 06/08/2026
@version 0
@param nBase, numérico, Medida do lado ou da base
@param [nAltura], numérico, Medida da altura
@param [nBaseMenor], numérico, Medida da base menor (trapézios)
@return numérico, Área calculada
/*/
user function goDrvIn(cAliasTemp)
	local cPedido		:= ""
	local cCliente		:= ""
	local cLoja			:= ""
	local dDtentrega	:= sToD("19941103") // dia do eclipse
	local cItem			:= ""
	local cSequen		:= ""
	local cProduto		:= ""
	local cDescri		:= ""
	local cArmazem		:= ""
	local cLote			:= ""
	local cEndereco		:= ""
	local cNumseri		:= ""
	local nQtdLib		:= -1

	local oDtEntrega	:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local aDtEntrJson	:= {}
	local oCliente		:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local aClientes		:= {}
	local oPedido		:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local aPedidos		:= {}
	local oItem			:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local aItens		:= {}
	local nI
	local aTokensDt
	local cTokenDt
	local aPostRet
	local oErroPost		:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local nIResponse
	local nIDetails
	local nAux

	oItem['code'] := "zero"
	aAdd(aItens, oItem)
	oPedido['items'] := aItens
	aAdd(aPedidos, oPedido)
	oCliente['orders'] := aPedidos
	aAdd(aClientes, oCliente)
	oDtEntrega['clients'] := aClientes

	(cAliasTemp)->(dbGoTop())
	while !(cAliasTemp)->(eOF())
		if (cAliasTemp)->SEL_OK == "  "
			(cAliasTemp)->(dbSkip())
			loop
		endIf

		if cPedido != (cAliasTemp)->C9_PEDIDO .or. cCliente != (cAliasTemp)->C9_CLIENTE .or. dDtentrega != (cAliasTemp)->C9_DATENT
			oPedido['items'] := aItens
			aAdd(aPedidos, oPedido)
			//novo json de pedido
			oPedido := JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
			aItens := {}

			oPedido['code'] := (cAliasTemp)->C9_PEDIDO
		endIf

		if cCliente != (cAliasTemp)->C9_CLIENTE .or. dDtentrega != (cAliasTemp)->C9_DATENT
			oCliente['orders'] := aPedidos
			aAdd(aClientes, oCliente)
			//novo json de cliente
			oCliente := JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
			aPedidos := {}

			oCliente['code'] := (cAliasTemp)->C9_CLIENTE
			oCliente['address'] := (cAliasTemp)->CLI_ENDERE
			oCliente['city'] := (cAliasTemp)->A1_MUN
			oCliente['country'] := (cAliasTemp)->YA_DESCR
			oCliente['name'] := (cAliasTemp)->A1_NOME
			oCliente['client_name'] := (cAliasTemp)->A1_NOME
		endIf

		if dDtentrega != (cAliasTemp)->C9_DATENT
			oDtEntrega['clients'] := aClientes
			aAdd(aDtEntrJson, {dDtentrega, oDtEntrega})
			//novo json de dtEntrega
			oDtEntrega := JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
			aClientes := {}
		endIf

		//novo json de itemSequencia1
		oItem := JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
		oItem['code'] := (cAliasTemp)->C9_ITEM + "-" + (cAliasTemp)->C9_SEQUEN + "-" + (cAliasTemp)->C9_PRODUTO
		oItem['description'] := (cAliasTemp)->B1_DESC
		oItem['units'] := (cAliasTemp)->C9_QTDLIB
		oItem['units_2'] := Posicione("SB1", 1, fwXFilial("SB1") + (cAliasTemp)->C9_PRODUTO, 'allTrim(str(SB1->B1_M3, tamSX3("B1_M3")[1], tamSX3("B1_M3")[2]))')
		aAdd(aItens, oItem)

		cPedido		:= (cAliasTemp)->C9_PEDIDO
		cCliente	:= (cAliasTemp)->C9_CLIENTE
		cLoja		:= (cAliasTemp)->C9_LOJA
		dDtentrega	:= (cAliasTemp)->C9_DATENT
		cItem		:= (cAliasTemp)->C9_ITEM
		cSequen		:= (cAliasTemp)->C9_SEQUEN
		cProduto	:= (cAliasTemp)->C9_PRODUTO
		cDescri		:= (cAliasTemp)->B1_DESC
		cArmazem	:= (cAliasTemp)->C9_LOCAL
		cLote		:= (cAliasTemp)->C9_LOTECTL
		cEndereco	:= (cAliasTemp)->PRD_ENDERE
		cNumseri	:= (cAliasTemp)->NUMSERI
		nQtdLib		:= (cAliasTemp)->C9_QTDLIB
		(cAliasTemp)->(dbSkip())
	endDo

	oPedido['items'] := aItens
	aAdd(aPedidos, oPedido)
	oCliente['orders'] := aPedidos
	aAdd(aClientes, oCliente)
	oDtEntrega['clients'] := aClientes
	aAdd(aDtEntrJson, {dDtentrega, oDtEntrega})

	if len(aDtEntrJson) < 2
		msgAlert("Não há envios", NOME_FONTE)
		return
	endIf

	for nI := 2 to len(aDtEntrJson)
		showLog("Enviar POST de:" + CRLF + VarInfo("Data de entrega " + cValToChar(nI) + " de " + cValToChar(len(aDtEntrJson)) + CRLF, aDtEntrJson[nI, 2]:ToJson(), /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
		aTokensDt := getTokenDt(aDtEntrJson[nI, 1])
		if valType(aTokensDt) == "C"
			exit
		endIf
		cTokenDt := escolheTk(aTokensDt)
		nAux := aScan(aTokensDt, {|x| cTokenDt == x['token']})
		if iif(!empty(cTokenDt), msgYesNo("Confirma o envio do POST?" + CRLF + "Data: " + dToC(aDtEntrJson[nI, 1]) + " Token: " + cTokenDt, NOME_FONTE), .F.)
			aPostRet := postPedido(cTokenDt, aDtEntrJson[nI, 2])
			(cAliasTemp)->(dbGoTop())
			while !(cAliasTemp)->(eOF())
				if empty((cAliasTemp)->SEL_OK) .or. aDtEntrJson[nI, 1] != (cAliasTemp)->C9_DATENT
					(cAliasTemp)->(dbSkip())
					loop
				endIf

				dbSelectArea("SC9")
				SC9->(dbSetOrder(1))
				if !SC9->(msSeek(fwXFilial('SC9') + (cAliasTemp)->C9_PEDIDO + (cAliasTemp)->C9_ITEM + (cAliasTemp)->C9_SEQUEN + (cAliasTemp)->C9_PRODUTO + "  " + "  ")) // C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN + C9_PRODUTO + C9_BLEST + C9_BLCRED
					msgAlert("Erro na atualização de dados após POST", NOME_FONTE)
					(cAliasTemp)->(dbSkip())
					loop
				endIf

				if aPostRet[1]
					recLock('SC9',.F.)
					SC9->C9_ZCENARI := dToC(aDtEntrJson[nI, 1]) + " " + aTokensDt[nAux]['description']// + " " + aTokensDt[nI]['schema_name']
					SC9->C9_ZDRIVIN := nil
					msUnLock()
					recLock((cAliasTemp),.F.)
					(cAliasTemp)->COMUNIC := 2
					(cAliasTemp)->SEL_OK := "  "
					msUnLock()
				elseIf !aPostRet[1]
					oErroPost:FromJSON(aPostRet[2])
					if len(oErroPost['response']) > 0
						for nIResponse := 1 to len(oErroPost['response'])
							if len(oErroPost['response'][nIResponse]['details']) > 0
								for nIDetails := 1 to len(oErroPost['response'][nIResponse]['details'])
									if oErroPost['response'][nIResponse]['details'][nIDetails]['data']['code'] == (cAliasTemp)->C9_CLIENTE
										recLock('SC9',.F.)
										SC9->C9_ZDRIVIN := aPostRet[2]
										msUnLock()
										recLock((cAliasTemp),.F.)
										(cAliasTemp)->COMUNIC := 4
										(cAliasTemp)->SEL_OK := "  "
										msUnLock()
									endIf
								next nIDetails
							endIf
						next nIResponse
					endIf
				endIf
				(cAliasTemp)->(dbSkip())
			endDo
		else
			msgAlert("Cancelado o envio do POST" + CRLF + "Data: " + dToC(aDtEntrJson[nI, 1]) + " Token: " + cTokenDt, NOME_FONTE)
		endIf
	next nI
	oMarkBrowse:refresh(.F.)
return

/*/{Protheus.doc} escolheTk
Permite usuário escolher o cenário onde será colocado os pedidos
@type static function
@author Julio Carvalho Barberino
@since 28/07/2026
@version 0
@param aTokensDt, array com dados mostrados durante a escolha do token
@return aDados[nI, 4], string com o token no Drivin
/*/
static function escolheTk(aTokensDt)
	local aDados		:= {}
	local nI
	local oDlg
	local oBrowTk
	local oOk			:= LoadBitmap(GetResources(), "LBOK") //CHECKED		//LBOK		//LBTIK
	local oNo			:= LoadBitmap(GetResources(), "LBNO") //UNCHECKED	//LBNO
	local oBtnConfir
	local cDia			:= subStr(aTokensDt[1]['deploy_date'], 9, 2) + "/" + subStr(aTokensDt[1]['deploy_date'], 6, 2) + "/" + subStr(aTokensDt[1]['deploy_date'], 1, 4)

	for nI := 1 to len(aTokensDt)
		aAdd(aDados, {iif(nI == 1, .t., .f.), aTokensDt[nI]['description'], aTokensDt[nI]['schema_name'], aTokensDt[nI]['token']}) // copia os dados do array de json num array de dados
	next nI

	oDlg := MsDialog():New(;
		20/*nTop*/, ;
		20/*nLeft*/, ;
		500/*nBottom*/, ;
		500/*nRight*/,;
		"Escolha um cenário para as entregas do dia " + cDia /*cTitle*/, ;
		/*cResName*/, ;
		/*hResources*/, ;
		/*.vbx.*/, ;
		/*nStyle*/,;
		/*nClrText*/, ;
		/*nClrBack*/, ;
		/*oBrush*/, ;
		/*oWnd*/, ;
		/*.pixel.*/,;
		/*oIco*/, ;
		/*oFont*/ , ;
		/*.status.*/)

	oBrowTk := TWBrowse():New(;
		10 /*nRow*/,;
		10 /*nCol*/,;
		300 /*nWidth*/,;
		100 /*nHeight*/,;
		/*bLine*/,;
		{"Selecione", "Plan", "Schema", "Token"} /*aHeaders*/,;
		/*aColSizes*/,;
		oDlg /*oDlg*/,;
		/*cField*/,;
		/*uValue1*/,;
		/*uValue2*/,;
		/*bChange*/,;
		{|nRow,nCol,nFlags| uniqueSel(oBrowTk)} /*bLDblClick bloco de código para o evento de duplo clique*/,;
		/*bRClick*/,;
		/*oFont*/,;
		/*oCursor*/,;
		/*nClrFore*/,;
		/*nClrBack*/,;
		/*cMsg*/,;
		.F. /*uParam20 para compatibilidade*/,;
		/*cAlias*/,;
		.T. /*lPixel*/,;
		/*bWhen*/,;
		/*uParam24*/,;
		/*bValid*/,;
		/*lHScroll*/,;
		/*lVScroll*/) // https://tdn.totvs.com/display/tec/TWBrowse		https://tdn.totvs.com/display/tec/TCBrowse

	oBrowTk:SetArray(aDados)
	oBrowTk:bLine := {|| {;
		iif(aDados[oBrowTk:nAt,1],oOK,oNO), ;
		aDados[oBrowTk:nAt,2], ;
		aDados[oBrowTk:nAt,3], ;
		aDados[oBrowTk:nAt,4], ;
		}}

	oBtnConfir := TButton():New(;
		110 /*nRow*/,;
		230 /*nCol*/,;
		"Confirma" /*cCaption*/,;
		oDlg /*oWnd*/,;
		{|| oDlg:end()}/*{uAction}*/,;
		60 /*nWidth*/,;
		15 /*nHeight*/,;
		/*nHelpId*/,;
		/*oFont*/,;
		/*.default.*/,;
		.T./*.pixel.*/,;
		/*.design.*/,;
		/*cMsg*/,;
		/*.update.*/,;
		{|| .T.} /*{WhenFunc}*/,;
		/*{uValid}*/,;
		/*.lCancel.*/)

	oDlg:Activate()

	for nI := 1 to len(aDados)
		if aDados[nI, 1]
			return aDados[nI, 4]
		endIf
	next nI
return // juk precisa tratar o que acontece se não tiver dados a retornar.

/*/{Protheus.doc} uniqueSel
Garante que seja escolhido apenas 1 token de cenario
@type static function
@author Julio Carvalho Barberino
@since 28/07/2026
@version 0
@param oBrowTk, TWBrowse com dados mostrados durante a escolha do token
/*/
static function uniqueSel(oBrowTk)
	local nI
	for nI := 1 to len(oBrowTk:aArray)
		oBrowTk:aArray[nI,1] := .F.
	next nI
	oBrowTk:aArray[oBrowTk:nAt,1] := !oBrowTk:aArray[oBrowTk:nAt,1]
	oBrowTk:refresh()
return

/*/{Protheus.doc} getTokenDt
Consulta o cenario token atraves de um GET no DrivIn
@type static function
@author Julio Carvalho Barberino
@since 25/07/2026
@version 0
@param dDtentrega, data de entrega
@return oJResposta['response'], array de jsons
/*/
static function getTokenDt(dDtentrega)
	local cDtEntrega	:= dToS(dDtentrega)
	local cUrl			:= superGetMV("SU_DIAPIUR", .T.)
	local cPath			:= superGetMV("SU_DICENAR", .T.) + "date=" + subStr(cDtEntrega, 1, 4) + "-" + subStr(cDtEntrega, 5, 2) + "-" + subStr(cDtEntrega, 7, 2)
	local cApiKey		:= superGetMV("SU_DIAPIKE", .T.)
	local oRestClient	:= FWRest():New(cUrl) // https://tdn.totvs.com/display/public/framework/FWRest
	local aHeader		:= {}
	local lRetOk
	local cRet
	local cErro
	local oJResposta	:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject

	Aadd(aHeader, "X-API-Key: " + cApiKey)
	Aadd(aHeader, "Content-Type: application/json")
	oRestClient:SetPath(cPath)
	lRetOk := oRestClient:get(aHeader)
	if lRetOk
		cRet := oRestClient:getResult()
	else
		cRet := oRestClient:getLastError()
		msgAlert("Houve erro no retorno do GET " + cPath + CRLF + cRet, NOME_FONTE)
		return ""
	endIf

	cErro := oJResposta:FromJSON(cRet)
	if !empty(cErro)
		msgAlert("Houve erro no retorno do GET " + cPath + CRLF + cErro, NOME_FONTE)
		return ""
	endIf

	if len(oJResposta['response']) == 0
		msgAlert("Houve erro no retorno do GET " + cPath + CRLF + "Array vazio", NOME_FONTE)
		return ""
	endIf
return oJResposta['response']

/*/{Protheus.doc} postPedido
Faz POST de pedidos no DrivIn
@type static function
@author Julio Carvalho Barberino
@since 25/07/2026
@version 0
@param cToken, token do cenario
@param oDtEntrega, json de pedidos para uma data de entrega
@return {.t., cRet}, array indicando se houve sucesso e mensagem de resposta
/*/
static function postPedido(cToken, oDtEntrega)
	local cUrl			:= superGetMV("SU_DIAPIUR", .T.)
	local cPath			:= superGetMV("SU_DIORDER", .T.) + "token=" + cToken
	local cApiKey		:= superGetMV("SU_DIAPIKE", .T.)
	local oRestClient	:= FWRest():New(cUrl) // https://tdn.totvs.com/display/public/framework/FWRest
	local aHeader		:= {}
	local cRet

	Aadd(aHeader, "X-API-Key: " + cApiKey)
	Aadd(aHeader, "Content-Type: application/json")
	oRestClient:SetPath(cPath)
	oRestClient:SetPostParams(oDtEntrega:ToJson())

	if oRestClient:post(aHeader)
		cRet := oRestClient:getResult()
		msgAlert(cRet, NOME_FONTE)
	else
		cRet := oRestClient:getLastError()
		msgAlert("ERRO no POST: " + CRLF + cRet + CRLF + oRestClient:getResult(), NOME_FONTE)
		return {.f., oRestClient:getResult(), cRet}
	endIf
return {.t., cRet}

/*/{Protheus.doc} rotaDrvDt
Monta markBrowse com rotas do DrivIn para uma data
@type user function
@author Julio Carvalho Barberino
@since 11/08/2026
@version 0
/*/
user function rotaDrvDt()
	local cUrl			:= superGetMV("SU_DIAPIUR", .T.)
	local cPath
	local aResp			:= {}
	local aTokensDt
	local oRestClient	:= FWRest():New(cUrl) // https://tdn.totvs.com/display/public/framework/FWRest
	local cApiKey		:= superGetMV("SU_DIAPIKE", .T.)
	local aHeader		:= {"X-API-Key: " + cApiKey, "Content-Type: application/json"}
	local oJsonReceb	:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local cJsonRaw

	local aEstrutura	:= {;
		{"ROTA",		"Rota",			"C",						6,							0,							""}, ;
		{"FLEET",		"Fleet",		"N",						6,							0,							""}, ;
		{"DEPLOY",		"Deploy",		"D",						8,							0,							""}, ;
		{"VEHICLE",		"Vehicle",		"C",						16,							0,							""}, ;
		{"DAK_COD",		"Comunic",		tamSX3("DAK_COD")[3],		tamSX3("DAK_COD")[1],		tamSX3("DAK_COD")[2],		""}, ;
		{"COMUNIC",		"Comunic",		"N",						1,							0,							""}, ;
		{"REC",			"Rec",			"N",						6,							0,							""}, ;
		{"SEL_OK",		"Sel",			"C",						2,							0,							""}}
	//	 Campo			Título			Típo						Tamanho						Decimais					Mascara
	local aCamposRed	:= {;
		{"ROTA",						"C",						6,							0}, ;
		{"FLEET",						"N",						6,							0}, ;
		{"DEPLOY",						"D",						8,							0}, ;
		{"VEHICLE",						"C",						16,							0}, ;
		{"DAK_COD",						tamSX3("DAK_COD")[3],		tamSX3("DAK_COD")[1],		tamSX3("DAK_COD")[2]}, ;
		{"COMUNIC",						"N",						1,							0}, ;
		{"REC",							"N",						6,							0}, ;
		{"SEL_OK",						"C",						2,							0}}
	//	 Campo							Típo						Tamanho						Decimais
	local cCampoIdx		:= "REC"
	local cCampoSel		:= "SEL_OK"
	local cAliasRote	:= getNextAlias()
	local cAliasDAK		:= getNextAlias()
	local oMarkBr
	local cAliasTemp
	local nIResponse
	local nCOMUNIC
	local cDAK_COD
	private dDtentrega
	private cTokenDt

	if !ParamBox({{1,		"Data de entrega",			date(),		"",		"",		"",		".T.",		100,		.F.}} /*aPerguntas configuradas*/, "Escolha uma data de entrega" /*Titulo*/, @aResp /*Vetor passado por referencia para retorno das respostas*/, /*bOk Code block para validar o botão Ok*/, /*aButtons Vetor com mais botões além dos botões de Ok e Cancel*/, /*lCentered Centralizar a janela*/, /*nPosX*/, /*nPosY*/, /*oPanel Caso quera adicionar a tela de perguntas a um painel já existente*/, /*cLoad Nome do perfil se caso for carregar*/, .T. /*lCanSave Salvar os dados informados nos parâmetros por perfil*/, .T. /*lUserSave Configuração por usuário*/)
		mesgAlert("Falha ao carregar data de entrega.", NOME_FONTE)
		return
	endIf

	dDtentrega := aResp[1]
	aTokensDt := getTokenDt(dDtentrega)
	cTokenDt := escolheTk(aTokensDt)
	cPath := superGetMV("SU_DIRESUL", .T.) + "token=" + cTokenDt + "&unassigned=1"
	oRestClient:SetPath(cPath)
	if oRestClient:get(aHeader)
		showLog(oRestClient:getResult())
		oJsonReceb:fromJson(oRestClient:getResult())
	else
		msgAlert("Houve erro no retorno do GET de cargas " + cPath + CRLF + oRestClient:getLastError(), NOME_FONTE)
		showLog(oRestClient:getResult())
		return
	endIf
	/*
		cJsonRaw := '{"status":"OK","success":true,"response":[{"vehicle":null,"description":null,"code":"001","scenario_description":"08.10-1","deploy_date":"2026-08-10","scenario_token":"5f3f186a-4577-458a-8b5b-aa4d753afcea","fleet_sequence":1,"skills":[],"driver":null,"peoneta":null,"summary":{"total_trips":1,"total_orders":1,"total_addresses":1,"total_distance":0.0,"total_time":40.0},"trips":[{"summary":{"trip_number":1,"total_orders":1,"total_addresses":1,"total_distance":0.0,"total_time":40.0,"code":null,"original_total_distance":0,"original_total_time_human":"00:40"},"driver":null,"peoneta":null,"work_shift_name":null,"approved_at":null,"started_at":null,"ended_at":null,"received_orders_size":0,"available_capacity":null,"available_time":null,"remaining_clearance":null,"results":[{"eta":"07:00","eta_started":null,"eta_mode":0,"deposit":true,"position":0,"real_distance":0.0,"planned_distance":null,"start_distance":null,"stop":{"code":null,"name":"MATRIZ CDD","client":null,"address_type":null,"address":"Sueñolar Ypacarai","reference":null,"city":"Ypacaraí","country":"Paraguay","lat":-25.3967453,"lng":-57.2789019,"service_time":null,"priority":null,"skills":null,"time_windows":null},"orders":[]},{"eta":"07:10","eta_started":null,"eta_mode":0,"deposit":false,"position":1,"real_distance":0.0,"planned_distance":0.0,"start_distance":null,"stop":{"code":"000004","name":"CALOTEIROS SMART CLUB                             ","client":"CALOTEIROS SMART CLUB                             ","address_type":null,"address":"RUA PASSA AMANHA QUE VEM, 45            ","reference":null,"city":"EMBUDAS        ","country":"AFEGANISTAO              ","lat":-23.442503,"lng":-58.443832,"service_time":20,"priority":2,"skills":[],"time_windows":[{"start":"07:00","end":"16:00"}]},"orde'
		cJsonRaw += 'rs":[{"idx":1,"code":"000026","units_1":1.0,"units_2":3.4,"units_3":0.0,"alt_code":null,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_9":null,"custom_10":null,"custom_11":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"delivery_date":null,"supplier_code":null,"supplier_name":null,"client_code":null,"client_name":"CALOTEIROS SMART CLUB                             ","contact_name":null,"contact_phone":null,"contact_email":null,"sales_zone_code":null,"sales_zone_name":null,"items":[{"code":"01-01-000007         ","description":"SUPER KOALA SUPERIOR PREMIUM                      ","units":1.0,"units_1":null,"units_2":3.1,"units_3":null,"units_4":0,"requested_units":0.0,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_10":null,"custom_11":null,"custom_12":null,"custom_13":null,"custom_14":null,"custom_15":null,"custom_16":null,"custom_17":null,"custom_18":null,"custom_19":null,"custom_20":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"number_5":null,"number_6":null,"number_7":null,"number_8":null,"number_9":null,"number_10":null,"item_contents":[]},{"code":"01-02-000007         ","description":"SUPER KOALA SUPERIOR PREMIUM                      ","units":1.0,"units_1":null,"units_2":3.1,"units_3":null,"units_4":0,"requested_units":0.0,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_10":null,"custom_11":null,"custom_12":null,"custom_13":null,"custom_14":null,"custom_15":null,"custom_16":null,"custom_17":null,"custom_18":null,"custom_19":null,"custom_20":null,"n'
		cJsonRaw += 'umber_1":null,"number_2":null,"number_3":null,"number_4":null,"number_5":null,"number_6":null,"number_7":null,"number_8":null,"number_9":null,"number_10":null,"item_contents":[]},{"code":"02-01-000008         ","description":"BOX KOALA TOP PLUS VISCO                          ","units":1.0,"units_1":null,"units_2":3.4,"units_3":null,"units_4":0,"requested_units":0.0,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_10":null,"custom_11":null,"custom_12":null,"custom_13":null,"custom_14":null,"custom_15":null,"custom_16":null,"custom_17":null,"custom_18":null,"custom_19":null,"custom_20":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"number_5":null,"number_6":null,"number_7":null,"number_8":null,"number_9":null,"number_10":null,"item_contents":[]}]}]},{"eta":"07:40","eta_started":null,"eta_mode":0,"deposit":true,"position":2,"real_distance":0.0,"planned_distance":0.0,"start_distance":null,"stop":{"code":null,"name":"MATRIZ CDD","client":null,"address_type":null,"address":"Sueñolar Ypacarai","reference":null,"city":"Ypacaraí","country":"Paraguay","lat":-25.3967453,"lng":-57.2789019,"service_time":null,"priority":null,"skills":null,"time_windows":null},"orders":[]}],"kpis":{"orders_pending":1,"orders_approved":0,"orders_partial":0,"orders_rejected":0,"return_eta":"07:40"}}]},{"vehicle":null,"description":null,"code":"002","scenario_description":"08.10-1","deploy_date":"2026-08-10","scenario_token":"5f3f186a-4577-458a-8b5b-aa4d753afcea","fleet_sequence":2,"skills":[],"driver":null,"peoneta":null,"summary":{"total_trips":1,"total_orders":1,"total_addresses":1,"total_distance":0.0,"total_time":40.0},"trips":[{"summary":{"trip_number":1,"total_orders":1,"total_addresses":1,"total_distance":0.0,"total_time":40.0,"co'
		cJsonRaw += 'de":null,"original_total_distance":0,"original_total_time_human":"00:40"},"driver":null,"peoneta":null,"work_shift_name":null,"approved_at":null,"started_at":null,"ended_at":null,"received_orders_size":0,"available_capacity":null,"available_time":null,"remaining_clearance":null,"results":[{"eta":"07:00","eta_started":null,"eta_mode":0,"deposit":true,"position":0,"real_distance":0.0,"planned_distance":null,"start_distance":null,"stop":{"code":null,"name":"MATRIZ CDD","client":null,"address_type":null,"address":"Sueñolar Ypacarai","reference":null,"city":"Ypacaraí","country":"Paraguay","lat":-25.3967453,"lng":-57.2789019,"service_time":null,"priority":null,"skills":null,"time_windows":null},"orders":[]},{"eta":"07:10","eta_started":null,"eta_mode":0,"deposit":false,"position":1,"real_distance":0.0,"planned_distance":0.0,"start_distance":null,"stop":{"code":"000006","name":"INTERPLANETARIOS LIDER                            ","client":"INTERPLANETARIOS LIDER                            ","address_type":null,"address":"AVENIDA FAROL IRLANDES, 181             ","reference":null,"city":"BARUEBAS       ","country":"ALEMANHA                 ","lat":-23.442503,"lng":-58.443832,"service_time":20,"priority":2,"skills":[],"time_windows":[{"start":"07:00","end":"16:00"}]},"orders":[{"idx":1,"code":"000028","units_1":1.0,"units_2":3.1,"units_3":0.0,"alt_code":null,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_9":null,"custom_10":null,"custom_11":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"delivery_date":null,"supp'
		cJsonRaw += 'lier_code":null,"supplier_name":null,"client_code":null,"client_name":"INTERPLANETARIOS LIDER                            ","contact_name":null,"contact_phone":null,"contact_email":null,"sales_zone_code":null,"sales_zone_name":null,"items":[{"code":"01-01-000007         ","description":"SUPER KOALA SUPERIOR PREMIUM                      ","units":1.0,"units_1":null,"units_2":3.1,"units_3":null,"units_4":0,"requested_units":0.0,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_10":null,"custom_11":null,"custom_12":null,"custom_13":null,"custom_14":null,"custom_15":null,"custom_16":null,"custom_17":null,"custom_18":null,"custom_19":null,"custom_20":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"number_5":null,"number_6":null,"number_7":null,"number_8":null,"number_9":null,"number_10":null,"item_contents":[]},{"code":"01-02-000007         ","description":"SUPER KOALA SUPERIOR PREMIUM                      ","units":1.0,"units_1":null,"units_2":3.1,"units_3":null,"units_4":0,"requested_units":0.0,"custom_1":null,"custom_2":null,"custom_3":null,"custom_4":null,"custom_5":null,"custom_6":null,"custom_7":null,"custom_8":null,"custom_10":null,"custom_11":null,"custom_12":null,"custom_13":null,"custom_14":null,"custom_15":null,"custom_16":null,"custom_17":null,"custom_18":null,"custom_19":null,"custom_20":null,"number_1":null,"number_2":null,"number_3":null,"number_4":null,"number_5":null,"number_6":null,"number_7":null,"number_8":null,"number_9":null,"number_10":null,"item_contents":[]}]}]},{"eta":"07:40","eta_starte'
		cJsonRaw += 'd":null,"eta_mode":0,"deposit":true,"position":2,"real_distance":0.0,"planned_distance":0.0,"start_distance":null,"stop":{"code":null,"name":"MATRIZ CDD","client":null,"address_type":null,"address":"Sueñolar Ypacarai","reference":null,"city":"Ypacaraí","country":"Paraguay","lat":-25.3967453,"lng":-57.2789019,"service_time":null,"priority":null,"skills":null,"time_windows":null},"orders":[]}],"kpis":{"orders_pending":1,"orders_approved":0,"orders_partial":0,"orders_rejected":0,"return_eta":"07:40"}}]}]}'
	*/
	oJsonReceb:fromJson(cJsonRaw)

	oRotasTab := FWTemporaryTable():new(cAliasRote, aCamposRed)
	oRotasTab:AddIndex("01", {cCampoIdx})
	oRotasTab:Create()
	msgAlert("Antes " + cAliasRote, NOME_FONTE)
	msgAlert("Depois " + cAliasRote, NOME_FONTE)
	cAliasRote := oRotasTab:getAlias()

	cQy := "SELECT " + CRLF
	cQy := "	DAK_COD, " + CRLF
	cQy := "	DAK_ZCENAR, " + CRLF
	cQy := "	DAK_ZDRVRT " + CRLF
	cQy := "FROM " + CRLF
	cQy := "	DAK990 " + CRLF
	cQy := "WHERE " + CRLF
	cQy := "	DAK_FILIAL = '" + fwXFilial("DAK") + "' "
	cQy := "	AND DAK_ZCENAR = '" + cTokenDt + "' "
	cQy := "	AND D_E_L_E_T_ = ''; "
	showLog(cQy)
	cAliasDAK := getNextAlias()
	dbUseArea(.T., "TOPCONN", TCGenQry(, , ChangeQuery(cQy)), cAliasDAK, .F., .T.)
	dbSelectArea(cAliasDAK)

	if 0 < len(oJsonReceb['response'])
		for nIResponse := 1 to len(oJsonReceb['response'])
			//marcador de nivel: oJsonReceb['response'][nIResponse]['scenario_token']
			(cAliasRote)->(dbAppend())
			(cAliasRote)->ROTA := oJsonReceb['response'][nIResponse]['code']
			(cAliasRote)->FLEET := oJsonReceb['response'][nIResponse]['fleet_sequence']
			(cAliasRote)->DEPLOY := sToD(strTran(oJsonReceb['response'][nIResponse]['deploy_date'], "-", ""))

			cDAK_COD := space(tamSX3("DAK_COD")[1])
			nCOMUNIC := 0
			(cAliasDAK)->(dbGoTop())
			while (cAliasDAK)->(eOF())
				if (cAliasDAK)->DAK_ZDRVRT == (cAliasRote)->ROTA
					cDAK_COD := (cAliasDAK)->DAK_COD
					nCOMUNIC := 1 // significa que tem DAK
				endIf
				(cAliasDAK)->(dbSkip())
			endDo

			(cAliasRote)->DAK_COD := cDAK_COD
			(cAliasRote)->COMUNIC := nCOMUNIC
			(cAliasRote)->REC := nIResponse
			(cAliasRote)->SEL_OK := "  " // juk pensar melhor em como será definido quais cargas serão gravadas. Não pode gravar o que já foi gravado, apenas avisar usuário o que já foi gravado e gravar o resto
			(cAliasRote)->(dbCommit())
		next nIResponse
	endIf
	(cAliasDAK)->(dbCloseArea())

	oMarkBr := jukMarkBrowse():New(aEstrutura, cAliasRote, cCampoIdx, cCampoSel)
	cAliasTemp := oMarkBr:getAliasTemp()
	oMarkBr:setARotina({;
		{"Importar p/ OMS",	'U_DrvToOMS("' + cAliasTemp + '")',			2,		0}})
	oMarkBr:jukPlay("Rotas para uma data")
return

/*/{Protheus.doc} DrvToOMS
Grava cargas do DrivIn no OMS do protheus
@type user function
@author Julio Carvalho Barberino
@since 11/08/2026
@version 0
@param cAliasTemp, alias de uma tabela com rotas
/*/
user function DrvToOMS(cAliasTemp)
	local nIResponse, nITrips, nIResults, nIOrders, nIItems
	local oArea			:= fwGetArea()
	local cItemC9
	local cPedido
	local cPedidoAux	:= ""
	local cItem
	local cSeq
	local cProd
	local cCliente
	local aCab, aItem

	dbSelectArea("SC9")
	SC9->(dbSetOrder(1))

	dbSelectArea("SA1")
	SA1->(dbSetOrder(1))

	dbSelectArea("SC5")
	SC5->(dbSetOrder(1))

	(cAliasTemp)->(dbGoTop())
	nIResponse := 1
	while (cAliasTemp)->(eOF())
		if (cAliasTemp)->SEL_OK == "  " .or. (cAliasTemp)->COMUNIC == 1
			loop
		endIf

		aCab := {;
			{"DAK_FILIAL",		fwXFilial("DAK"),					Nil}, ;
			{"DAK_COD",			getSX8Num("DAK","DAK_COD"),		Nil} /*Campo com inicializador padrão para pegar GESX8NUM*/, ;
			{"DAK_SEQCAR",		"01",							Nil}, ;
			{"DAK_ROTEIR",		"999999",						Nil}, ;
			{"DAK_CAMINH",		"",								Nil}, ;
			{"DAK_MOTORI",		"",								Nil}, ;
			{"DAK_PESO",		0,								Nil} /*Calculado pelo OMSA200*/, ;
			{"DAK_DATA",		date(),							Nil}, ;
			{"DAK_HORA",		time(),							Nil}, ;
			{"DAK_JUNTOU",		"Manual",						Nil}, ;
			{"DAK_ACECAR",		"2",							Nil}, ;
			{"DAK_ACEVAS",		"2",							Nil}, ;
			{"DAK_ACEFIN",		"2",							Nil}, ;
			{"DAK_FLGUNI",		"2",							Nil} /*Campo com inicializador padrão  - 2*/, ;
			{"DAK_TRANSP",		"",								Nil}, ;
			{"DAK_ZCENAR",		cTokenDt,						nil}, ;
			{"DAK_ZDRVRT",		(cAliasTemp)->ROTA,				nil}, ;
			}
		aItem := {}

		// marcador de nivel: cenario = oJsonReceb['response'][nIResponse]['scenario_token']
		if 0 < len(oJsonReceb['response'][nIResponse]['trips'])
			for nITrips := 1 to len(oJsonReceb['response'][nIResponse]['trips'])
				// marcador de nivel: viagem/rota = oJsonReceb['response'][nIResponse]['trips'][nITrips]
				if 0 < len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'])
					for nIResults := 1 to len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results']) // talvez precise fazer for nIResults := 2 to len() - 1
						// marcador de nivel: parada = oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]
						if 0 < len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'])
							for nIOrders := 1 to len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'])
								// marcador de nivel: pedido oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'][nIOrders]['code']
								cPedido := oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'][nIOrders]['code']
								if 0 < len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'][nIOrders]['items'])
									for nIItems := 1 to len(oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'][nIOrders]['items']) // Ufa chegei até aqui \o/
										// marcador de nivel: item de pedido C9
										cItemC9 := oJsonReceb['response'][nIResponse]['trips'][nITrips]['results'][nIResults]['orders'][nIOrders]['items'][nIItems]['code']
										cItem := subStr(cItemC9, 1, tamSX3("C9_ITEM")[1])
										cSeq := subStr(cItemC9, tamSX3("C9_ITEM")[1] + 2, tamSX3("C9_SEQUEN")[1])
										cProd := subStr(cItemC9, tamSX3("C9_ITEM")[1] + tamSX3("C9_SEQUEN")[1] + 3, len(cItemC9) - 6)
										cProd := padR(cProd /*xExp*/, tamSX3("C9_PRODUTO")[1] /*nLen*/, " "/*cFill*/)

										if !SC9->(msSeek(fwXFilial('SC9') + cPedido + cItem + cSeq + cProd + "  " + "  ")) // C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN + C9_PRODUTO + C9_BLEST + C9_BLCRED
											msgAlert("SC9 não encontrado.", NOME_FONTE)
											loop
										endIf

										if !SA1->(msSeek(fwXFilial('SA1') + SC9->C9_CLIENTE + SC9->C9_LOJA)) // A1_FILIAL + A1_COD + A1_LOJA
											msgAlert("SA1 não encontrado.", NOME_FONTE)
											loop
										endIf

										if !SC5->(msSeek(fwXFilial('SC5') + cPedido)) // C5_FILIAL + C5_NUM
											msgAlert("SC5 não encontrado.", NOME_FONTE)
											loop
										endIf
										if cPedidoAux != cPedido // juk impede dois aItem para o mesmo pedido
											Aadd(aItem, ;
												{;
												aCab[2,2]			/*01 - Código da carga*/, ;
												"999999"			/*02 - Código da Rota - 999999 (Genérica)*/, ;
												"999999"			/*03 - Código da Zona - 999999 (Genérica)*/, ;
												"999999"			/*04-	Código do Setor - 999999 (Genérico)*/, ;
												SC5->C5_NUM			/*05 - Código do Pedido Venda*/, ;
												SA1->A1_COD			/*06 - Código do Cliente*/, ;
												SA1->A1_LOJA		/*07 - Loja do Cliente*/, ;
												SA1->A1_NOME		/*08 - Nome do Cliente*/, ;
												SA1->A1_BAIRRO		/*09 - Bairro do Cliente*/, ;
												SA1->A1_MUN			/*10 - Município do Cliente*/, ;
												SA1->A1_EST			/*11 - Estado do Cliente*/, ;
												SC5->C5_FILIAL		/*12 - Filial do Pedido Venda*/, ;
												SA1->A1_FILIAL		/*13 - Filial do Cliente*/, ;
												0					/*14 - Peso Total dos Itens (Calculado pelo OMSA200)*/, ;
												0					/*15 - Volume Total dos Itens (Calculado pelo OMSA200)*/, ;
												"08:00"				/*16 - Hora Chegada*/, ;
												"0001:00"			/*17 - Time Service*/, ;
												Nil					/*18 - Não Usado*/, ;
												dDatabase			/*19 - Data Chegada*/, ;
												dDatabase			/*20 - Data Saída*/, ;
												Nil					/*21 - Não Usado*/, ;
												Nil					/*22 - Não Usado*/, ;
												0					/*23 - Valor do Frete*/, ;
												0					/*24 - Frete Autonomo*/, ;
												0					/*25 - Valor Total dos Itens (Calculado pelo OMSA200)*/, ;
												0					/*26 - Quantidade Total dos Itens (Calculado pelo OMSA200)*/, ;
												Nil					/*27 - Não usado*/, ;
												"000004"			/*28 - Transportadora redespachante (não obrigatório)*/;
												})
											cPedidoAux = cPedido
										endIf
									next nIItems
								endIf

							next nIOrders
						endIf

					next nIResults
				endIf

			next nITrips
		endIf

		(cAliasTemp)->(dbSkip())
		nIResponse += 1
	endDo

	MSExecAuto( { |x, y, z| OMSA200(x, y, z) }, aCab, aItem, 3 )
	If lMsErroAuto
		Alert("Erro no ExecAuto do OMSA200")
		cMsgErro := MostraErro()
		DisarmTransaction()
		Alert(cMsgErro)
	Else
		Alert("Sucesso na execução do ExecAuto OMSA200")
	EndIf

	SC5->(dbCloseArea())
	SA1->(dbCloseArea())
	SC9->(dbCloseArea())
	fwRestArea(oArea)
return

/*/{Protheus.doc} OM200CAR
Ponto de entrada para alterar a query que indica quais registros da C9 serão pegos pelo OMS https://tdn.totvs.com/pages/releaseview.action?pageId=600804956
@type user function
@author Julio Carvalho Barberino
@since 25/08/2026
@version 0
@return cQuery, query apos alteração
/*/
user function OM200CAR()
	local cQuery := PARAMIXB[1]

	showLog(cQuery)
	if FWIsInCallStack("U_DrvToOMS") .or. FWIsInCallStack("U_jukTest") // juk retirar o trecho .or. FWIsInCallStack("U_jukTest")
		cQuery := strTran(cQuery, " ORDER BY", " AND SC9.C9_DATENT = '" + dToS(dDateC9) + "' ORDER BY")
	endIf
	showLog(cQuery)
return cQuery

/*/{Protheus.doc} OM200QRY
Ponto de entrada para alterar a query que indica quais registros da C9 serão mostrados pelo OMS https://tdn.totvs.com/display/public/PROT/DT+PE+OM200QRY+-+Filtro+dos+pedidos+apresentados+na+tela+de+montagem+de+carga https://tdn.totvs.com/pages/releaseview.action?pageId=600804368
@type user function
@author Julio Carvalho Barberino
@since 25/08/2026
@version 0
@return cQuery, query apos alteração
/*/
user function OM200QRY()
	local cQuery		:= PARAMIXB[1] //Query para a manutenção
	local aArrayTipo	:= PARAMIXB[2] //Tipos de carga selecionados
	local aArrayMod		:= PARAMIXB[3] //Modelos de carga
	local nQuery		:= PARAMIXB[4] //Número da query no UNION (1,2)

	showLog(cQuery)
	if nQuery == 2 .and. FWIsInCallStack("U_DrvToOMS") .or. FWIsInCallStack("U_jukTest") // juk retirar o trecho .or. FWIsInCallStack("U_jukTest")
		cQuery += " AND SC9.C9_DATENT = '" + dToS(dDateC9) + "'"
	endIf
	showLog(cQuery)
return cQuery
