#INCLUDE "protheus.ch"

#DEFINE NOME_FONTE "NEXACD.PRW"
#DEFINE compEmpre "99"

//INCLUSAO 
user function aptProd(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
	local aVetor
	local aRet		:= {.T., "gravou Ok"}
	local nOpc		:= 3

	conOut("user function aptProd INICIO " + NOME_FONTE)

	RpcSetType(3) // Ninguém sabe pra que isso serve
	RpcSetEnv(compEmpre /*cRpcEmp*/, ;
		cFilia /*cRpcFil*/, ;
		/*cEnvUser*/, ;
		/*cEnvPass*/, ;
		"EST" /*cEnvMod*/, ;
		"MATA250" /*cFunName*/, ;
		/*aTables*/, ;
		/*lShowFinal*/, ;
		/*lAbend*/, ;
		/*lOpenSX*/, ;
		/*lConnect*/) /* https://tdn.totvs.com/display/public/framework/RpcSetEnv */

	aVetor := {;
		{"D3_OP",			cOp,				NIL},;
		{"D3_TM",			"010",				NIL},;
		{"D3_COD",			cCodProd,			NIL},;
		{"D3_DESCRI",		cDescr,				NIL},;
		{"D3_LOCAL",		cArmazem,			NIL},;
		{"D3_LOTECTL",		cLote,				NIL},;
		{"D3_QUANT",		nQuant,				NIL},;
		{"D3_NUMSERI",		cSerie,				NIL};
		}

	conOut(VarInfo("aVetor", aVetor, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	
	lMsErroAuto		:= .F.
	
	MSExecAuto({|x, y| mata250(x, y)}, aVetor, nOpc)

	if lMsErroAuto
		aRet[1] := .F.
		aRet[2] := Mostraerro("\temp\erro.txt")
		conOut(VarInfo("aRet", aRet, /*espaçamento deve ser adicionado a cada -tab-*/, .F. /*HTML (.T.) ou TXT (.F.)*/))
	endIf
	
	conOut("user function aptProd FIM " + NOME_FONTE)
return aRet
