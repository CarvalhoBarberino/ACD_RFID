#INCLUDE "protheus.ch"

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
		aRet[2] := Mostraerro("\temp\erro.txt")
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

	if "N" == Posicione("SB1", 1, cFilia + cCodProd, "B1_LOCALIZ") // B1_FILIAL + B1_COD
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
		{"DB_QUANT",		nQuant,			Nil};
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
		aRet[2] := Mostraerro("\temp\erro.txt")
		conOut(VarInfo("aRet", aRet, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
		conOut("user function U_endereca FIM erro " + NOME_FONTE)
		fwRestArea(oArea)
		return aRet
	endIf

	aRet[1] := .T.
	aRet[2] := posicione("SDB", 1, cFilia + cCodProd + cArmazem + cNumseq + cOp, "DB_LOCALIZ") // DB_FILIAL + DB_PRODUTO + DB_LOCAL + DB_NUMSEQ + DB_DOC
	conOut("linha 111")
	conOut("user function U_endereca FIM ok " + NOME_FONTE)
	fwRestArea(oArea)
return aRet
