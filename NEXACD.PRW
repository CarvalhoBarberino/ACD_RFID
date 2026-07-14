#INCLUDE "protheus.ch"
#INCLUDE "RWMAKE.CH"

#DEFINE NOME_FONTE "NEXACD.PRW"

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

user function endereca(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local oArea				:= fwGetArea()
	local aRet				:= {.T., ""}
	local cQy				:= ""
	local cAliasD3			:= getNextAlias()
	local cNumseq
	local aItensSDB			:= {}
	local aCabSDA
	local aItSDB
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
		{"DB_LOCALIZ",		"APT",			Nil},;
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
	dbSetOrder(1)

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
			{"ZB0_LOCALI",		SDB->DB_LOCALIZ}, ;
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

user function CBRETEAN()
	local oArea				:= fwGetArea()
	local cId				:= padR(paramIXB[1], tamSX3("ZB0_CODETI")[1])
	local aRet				:= {}

	dbSelectArea('ZB0')
	dbSetOrder(1)
	msSeek(fwXFilial('ZB0') + cId)

	aRet := {;
		ZB0->ZB0_CODPRO, ;
		ZB0->ZB0_QTDE, ;
		ZB0->ZB0_LOTE, ;
		NIL, ;
		ZB0->ZB0_NUMSER, ;
		ZB0->ZB0_LOCALI;
	}

	fwRestArea(oArea)
return aRet // Espera devolver aRet = {"Código do Produto","Quantidade(Embalagem normalmente analisado na nQE := SB1->B1_QE no processo padrão)","Lote","Data de Validade","Número de Série","Endereço Destino"}
