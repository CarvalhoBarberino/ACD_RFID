#INCLUDE "protheus.ch"
#INCLUDE "RWMAKE.CH"

#DEFINE NOME_FONTE		"NEXACD.PRW"
#DEFINE BEARER_TOKEN	""
#DEFINE API_KEY			"647fbc3a-9e8d-49b8-ba28-b5ec3d72b673"
#DEFINE ORACLE

/*/{Protheus.doc} aptProd
	Funcao faz apontamento de producao. Eh chamado pelo webservice nexSolucoes
	@type user function
	@author Julio Carvalho Barberino
	@since 09/07/2026
	@version 0
/*/
user function aptProd(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local aVetor
	local aRet				:= {.T., "gravou Ok"}
	local nOpc				:= 3

	conOut("user function U_aptProd INICIO " + NOME_FONTE)

	aVetor := {;
		{"D3_OP",			cOp,				NIL},;
		{"D3_TM",			"010",				NIL},;
		{"D3_COD",			cCodProd,			NIL},;
		{"D3_DESCRI",		cDescr,				NIL},;
		{"D3_LOCAL",		cArmazem,			NIL},;
		{"D3_LOTECTL",		cLote,				NIL},;
		{"D3_QUANT",		nQuant,				NIL};
		}

	conOut(VarInfo("aVetor", aVetor, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))

	lMsErroAuto		:= .F.
	MSExecAuto({|x, y| mata250(x, y)}, aVetor, nOpc)

	if lMsErroAuto
		conOut("linha 28")
		aRet[1] := .F.
		aRet[2] := mostraErro("\temp\erro.txt")
		conOut(VarInfo("aRet", aRet, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	endIf

	conOut("user function U_aptProd FIM ok " + NOME_FONTE)
return aRet

/*/{Protheus.doc} endereca
	Funcao faz enderecamento lotes recem produzidos. Eh chamado pelo webservice nexSolucoes
	@type user function
	@author Julio Carvalho Barberino
	@since 10/07/2026
	@version 0
/*/
user function endereca(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local oArea				:= fwGetArea()
	local aRet				:= {.T., ""}
	local cQy				:= ""
	local cAliasD3			:= getNextAlias()
	local cNumseq
	local aItensSDB			:= {}
	local aCabSDA
	local aItSDB
	local cAptEnd			:= superGetMV("NX_APTEND", .F., "APT")
	private lMsErroAuto

	conOut("user function U_endereca INICIO " + NOME_FONTE)

	if "N" == posicione("SB1", 1, cFilia + cCodProd, "B1_LOCALIZ") // B1_FILIAL + B1_COD
		aRet[1] := .T.
		aRet[2] := "não endereçar"
		conOut(aRet[2] + " " + NOME_FONTE)
		fwRestArea(oArea)
		return aRet
	endIf

	cQy += "SELECT TOP 1 " + CRLF
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
	conOut(cQy)
	dbUseArea(.T., "TOPCONN", TCGenQry(, , cQy), cAliasD3, .T., .T.)
	dbSelectArea(cAliasD3)
	(cAliasD3)->(dbGoTop())
	cNumseq := alltrim((cAliasD3)->D3_NUMSEQ)
	(cAliasD3)->(dbCloseArea())
	conOut(cNumseq)

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
	conOut(VarInfo("aCabSDA", aCabSDA, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	conOut(VarInfo("aItensSDB", aItensSDB, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	//Executa o endere?amento do item
	lMsErroAuto := .F.
	MATA265(aCabSDA, aItensSDB, 3) // Necessita declara antes (lá em cima) private lMsErroAuto
	conOut(VarInfo("lMsErroAuto", lMsErroAuto, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	if lMsErroAuto
		conOut("linha 100")
		aRet[1] := .F.
		aRet[2] := mostraErro("\temp\erro.txt")
		conOut(VarInfo("aRet", aRet, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
		conOut("user function U_endereca FIM erro " + NOME_FONTE)
		fwRestArea(oArea)
		return aRet
	endIf

	aRet[1] := .T.
	aRet[2] := posicione("SDB", 1, cFilia + padR(cCodProd, tamSx3("DB_PRODUTO")[1], " ") + cArmazem + cNumseq + cOp, "DB_LOCALIZ") // DB_FILIAL + DB_PRODUTO + DB_LOCAL + DB_NUMSEQ + DB_DOC
	conOut("linha 111")
	conOut("user function U_endereca FIM ok " + NOME_FONTE)
	fwRestArea(oArea)
return aRet

/*/{Protheus.doc} criarZB0
	Funcao registra dados na tabela ZB0. Eh chamado no ponto de entrada MTA265I
	@type user function
	@author Julio Carvalho Barberino
	@since 20/07/2026
	@version 0
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
		conout("O tipo de dados deveria ser um Array" + NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
		msgAlert("O tipo de dados deveria ser um Array", NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
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
		If len(tamSx3(aDadosZB0[nI][1])) == 0
			conOut("O campo " + aDadosZB0[nI][1] + " não existe." + NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
			msgAlert("O campo " + aDadosZB0[nI][1] + " não existe.", NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
		endIf
		cTipoEsperado := tamSx3(aDadosZB0[nI][1])[3]
		cTipoRecebido := valType(aDadosZB0[nI][2])
		lTipoIgual := (cTipoRecebido == cTipoEsperado)
		lTamanhoOk := iif(cTipoRecebido == "C", len(aDadosZB0[nI][2]) <= tamSx3(aDadosZB0[nI][1])[1], .T.)
		If lTipoIgual .and. lTamanhoOk
			ZB0->&(aDadosZB0[nI][1]) := aDadosZB0[nI][2]
		Else
			conOut("O campo " + aDadosZB0[nI][1] + " não foi gravado." + CRLF + ;
				"Tipo esperado: " + cTipoEsperado + CRLF + "Tipo recebido: " + cTipoRecebido + CRLF + ;
				"Tamanho esperado: " + str(tamSx3(aDadosZB0[nI][1])[1], 4, 0) + "Tamanho recebido: " + str(len(aDadosZB0[nI][2]), 4, 0) + ;
				NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
			msgAlert("O campo " + aDadosZB0[nI][1] + " não foi gravado." + CRLF + ;
				"Tipo esperado: " + cTipoEsperado + CRLF + "Tipo recebido: " + cTipoRecebido + CRLF + ;
				"Tamanho esperado: " + str(tamSx3(aDadosZB0[nI][1])[1], 4, 0) + "Tamanho recebido: " + str(len(aDadosZB0[nI][2]), 4, 0), ;
				NOME_FONTE + " Ocorreu um erro ao gravar ZB0")
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
/*/
user function MTA265I()
	local aDadosZB0
	local oArea
	if !empty(allTrim(SDB->DB_ZB0COD))
		conOut(NOME_FONTE + "ZB0_CODETI: " + SDB->DB_ZB0COD)
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
	Ponto de entrada chamado quando faz leitura do codigo de barras no coletor
	@type user function
	@author Julio Carvalho Barberino
	@since 14/07/2026
	@version 0
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

/*/{Protheus.doc} MTA650MNU
	Ponto de entrada chamado no carregamento de opcoes da rotina Ordem de Producao https://tdn.totvs.com/display/public/PROT/MTA650MNU
	@type user function
	@author Julio Carvalho Barberino
	@since 20/07/2026
	@version 0
/*/
user function opToSegel()
	local oArea			:= fwGetArea()
	local aHeader		:= {}
	local cCodProd		:= allTrim(SC2->C2_PRODUTO)
	local cOp			:= allTrim(SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
	local cUrl			:= "localhost:8080" // juk Criar parametro para estes enderecos
	local cPath			:= "/rest/nexsolucoes/production_order"
	local lRetOk
	local oRestClient	:= FWRest():New(cUrl) // https://tdn.totvs.com/display/public/framework/FWRest
	local oJReq			:= JsonObject():New() // https://tdn.totvs.com/display/tec/Classe+JsonObject
	local cRet			:= ""
	local cToken		:= BEARER_TOKEN

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
	oJReq["filial"] := SC2->C2_FILIAL
	oJReq["op"] := cOp
	oJReq["cod_prod"] := cCodProd
	oJReq["descricao"] := allTrim(SB1->B1_DESC)
	oJReq["local"] := SC2->C2_LOCAL
	oJReq["lote"] := cOp
	oJReq["qtd"] := SC2->C2_QUANT
	oJReq["familia"] := "teste" // juk precisa descobrir o nome do campo customizado que já existe na SB1 da Suenolar

	Aadd(aHeader, "Content-Type: application/json")
	Aadd(aHeader, "Authorization: Bearer " + cToken)
	//Aadd(aHeader, "Authorization: Basic " + Encode64("app01:fTdUlDgdQQ4MRQhLahykiKhON6k97Zfly5SV6fwpa5zCE"))
	oRestClient:SetPath(cPath)
	oRestClient:SetPostParams(oJReq:ToJson())

	lRetOk := oRestClient:post(aHeader)
	if lRetOk
		cRet += "ACERTADÃO " + oRestClient:getResult()
	else
		cRet += "ERRINHO " + oRestClient:getLastError()
	endIf

	msgAlert(cRet, NOME_FONTE) // juk Continuar daqui. Precisa decidir o que fazer com a informação de retorno. Precisa criar campo na SC2 pra guardar o retorno

	fwRestArea(oArea)
	conOut("opToSegel() FIM" + NOME_FONTE)
return

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
	cQy += "		ON A1.A1_FILIAL = '  ' " + CRLF
	cQy += "		AND A1_COD = C9_CLIENTE " + CRLF
	cQy += "		AND A1.D_E_L_E_T_ = '' " + CRLF
	cQy += "	INNER JOIN " + CRLF
	cQy += "		" + retSqlName("SYA") + " YA " + CRLF
	cQy += "		ON YA.YA_FILIAL = '  ' " + CRLF
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
	cQy += "	C9_FILIAL = '" + fwXFilial("SC9") + "' " + CRLF
	cQy += "	AND C9_PEDIDO BETWEEN '" + cPedidoDe + "' AND '" + cPedidoAte + "' " + CRLF
	cQy += "	AND C9_CLIENTE BETWEEN '" + cCliDe + "' AND '" + cCliAte + "' " + CRLF
	cQy += "	AND C9_LOJA BETWEEN '" + cLojaDe + "' AND '" + cLojaAte + "' " + CRLF
	cQy += "	AND C9_DATENT BETWEEN '" + dToS(dDataDe) + "' AND '" + dToS(dDataAte) + "' " + CRLF
	cQy += "	AND C9_PRODUTO BETWEEN '" + cProdDe + "' AND '" + cProdAte + "' " + CRLF
	cQy += "	AND C9_BLEST = '' " + CRLF
	cQy += "	AND C9_BLCRED = '' " + CRLF
	cQy += "	AND C9.D_E_L_E_T_ = '' " + CRLF
	cQy += "ORDER BY " + CRLF
	cQy += "	C9_PEDIDO, " + CRLF
	cQy += "	C9_ITEM, " + CRLF
	cQy += "	C9_SEQUEN; "
	showLog(ChangeQuery(cQy))
	showLog(cQy)

	dbUseArea(.T., "TOPCONN", TCGenQry(, , ChangeQuery(cQy)), cAliasC9, .F., .T.)
	dbSelectArea(cAliasC9)
	(cAliasC9)->(dbGoTop())

	oObjeto1 := jukMarkBrowse():New(aEstrutura, cAliasC9, cCampoIdx, cCampoSel)
	cAliasTemp := oObjeto1:getAliasTemp()
	oObjeto1:setARotina({;
		{"Enviar p/ DriveIn",	'U_goDrvIn("' + cAliasTemp + '")',			2,		0}, ;
		{"Inspecionar erro",	'U_inspGoDrvI("' + cAliasTemp + '")',		2,		0}})
	oObjeto1:jukPlay("Liberações a enviar para DrivIn")
return

user function inspGoDrvI(cAliasTemp)

	dbSelectArea("SC9")
	SC9->(dbSetOrder(1))
	if !SC9->(msSeek(fwXFilial('SC9') + (cAliasTemp)->C9_PEDIDO + (cAliasTemp)->C9_ITEM + (cAliasTemp)->C9_SEQUEN + (cAliasTemp)->C9_PRODUTO + "  " + "  ")) // C9_FILIAL + C9_PEDIDO + C9_ITEM + C9_SEQUEN + C9_PRODUTO + C9_BLEST + C9_BLCRED
		msgAlert("Erro de posicionamento na tabela SC9", NOME_FONTE)
		return
	endIf

	showLog(SC9->C9_ZDRIVIN)
return

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

	conOut("goDrvIn() INICIO" + NOME_FONTE)

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
	conOut("goDrvIn() FIM" + NOME_FONTE)
return

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

static function uniqueSel(oBrowTk)
	local nI
	for nI := 1 to len(oBrowTk:aArray)
		oBrowTk:aArray[nI,1] := .F.
	next nI
	oBrowTk:aArray[oBrowTk:nAt,1] := !oBrowTk:aArray[oBrowTk:nAt,1]
	oBrowTk:refresh()
return

static function getTokenDt(dDtentrega)
	local cDtEntrega	:= dToS(dDtentrega)
	local cUrl			:= "https://external-qa.driv.in/api/external/v2" // juk Criar parametro para estes enderecos
	local cPath			:= "/scenarios?date=" + subStr(cDtEntrega, 1, 4) + "-" + subStr(cDtEntrega, 5, 2) + "-" + subStr(cDtEntrega, 7, 2) // exemplo "/scenarios?date=2026-07-25"
	local cApiKey		:= API_KEY
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

static function postPedido(cToken, oDtEntrega)
	local cUrl			:= "https://external-qa.driv.in/api/external/v2" // juk Criar parametro para estes enderecos
	local cPath			:= "/orders?token=" + cToken
	local cApiKey		:= API_KEY
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
