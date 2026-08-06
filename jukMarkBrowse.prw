#INCLUDE "protheus.ch"
#INCLUDE "totvs.ch"

#DEFINE NOME_FONTE "jukMarkBrowse"

/*/{Protheus.doc} jukMarkBrowse
Classe para adaptar alias a um markBrowse
@author Julio Carvalho
@since 06/05/2026
@example
	//Exemplo de uso

	//Antes de usar a classe jukMarkBrowse, deve existir um Alias com os
	//dados que serão mostrados no markBrowse e portanto já deve conter
	//o campo de indice (neste exemplo REC) e também deve conter o campo
	//seletor (neste exemplo SEL_OK). O alias pode ser criado por uma
	//query. Eu não sei como você ira criar o Alias mas precisa existir
	//um campo como indice e um campo como seletor.

	local cAliasTemp
	local aRotina
	//Exemplo de array com estrutura dos campos de um Alias.
	local aEstrutura := {;
		{"CB7_FILIAL",		"Filial",			"C",		2,			0,			""},;
		{"CB7_ORDSEP",		"Ord Sep",			"C",		6,			0,			""},;
		{"CB7_PEDIDO",		"Pedido",			"C",		6,			0,			""},;
		{"CB7_CLIENT",		"Cliente",			"C",		6,			0,			""},;
		{"CB7_LOJA",		"Loja",				"C",		2,			0,			""},;
		{"CB7_STATUS",		"Status",			"C",		1,			0,			""},;
		{"CB7_ORIGEM",		"Origem",			"C",		1,			0,			""},;
		{"CB8_ITEM",		"Item",				"C",		2,			0,			""},;
		{"CB8_PROD",		"Produto",			"C",		15,			0,			""},;
		{"B1_DESC",			"Descrição",		"C",		50,			0,			""},;
		{"B1_UM",			"Unidade",			"C",		2,			0,			""},;
		{"CB8_LOCAL",		"Local",			"C",		2,			0,			""},;
		{"CB8_LOTECT",		"Lote",				"C",		10,			0,			""},;
		{"CB8_NUMLOT",		"subLote",			"C",		6,			0,			""},;
		{"CB8_LCALIZ",		"Endereço",			"C",		15,			0,			""},;
		{"CB8_NUMSER",		"Num Serie",		"C",		20,			0,			""},;
		{"CB8_QTDORI",		"Qtd. Original",	"N",		12,			2,			""},;
		{"CB8_SALDOS",		"Saldo",			"N",		12,			2,			""},;
		{"CB7_DTEMIS",		"Emissão",			"D",		8,			0,			""},;
		{"REC",				"Rec",				"N",		14,			0,			""},;
		{"SEL_OK",			"Sel",				"C",		2,			0,			""}}
	//	 Campo				Título				Típo		Tamanho		Decimais	Mascara
	
	//Define qual campo será utilizado como indice
	local cCampoIdx		:= "REC"
	
	//Define qual campo será utilizado como seletor do markBrowse
	local cCampoSel		:= "SEL_OK"

	//Cria o objeto que adapta para o markBrowse
	oObjeto1 := jukMarkBrowse():New(aEstrutura, cAliasQry, cCampoIdx, cCampoSel)

	//Define variavel que irá guardar o alias temporário
	cAliasTemp := oObjeto1:getAliasTemp()

	//Define o array aRotina
	aRotina := {;
	{"Agrupar",				'U_agruparOS("' + cAliasTemp + '")',		2,			0},;
	{'Incluir',				'VIEWDEF.MVC01',							3,			0},;
	{'Alterar',				'VIEWDEF.MVC01',							4,			0},;
	{'Excluir',				'VIEWDEF.MVC01',							5,			0},;
	{'Imprimir',			'VIEWDEF.MVC01',							8,			0},;
	{'Copiar',				'VIEWDEF.MVC01',							9,			0},;
	{'SubMenu',				;
	{;
	{'Funcao 1 subMenu',	'Alert("Sub menu funcao 1")',				4,			0},;
	{'Funcao 2 subMenu',	'Alert("Sub menu funcao 2")',				4,			0};
	},																	9,			0};
	}
	//Titulo				funcao										operacao	acesso

	//passa o array aRotina para dentro do objeto que ira adaptar o markBrowse
	//oObjeto1:setARotina(aRotina)
 
	//Executa o markBrowse
	oObjeto1:jukPlay()
/*/

class jukMarkBrowse
	data aCampos
	data cAliasQuery
	data cAliasTemp
	data cCampoIndice
	data cCampoSel
	data lValidado
	data oColumn
	data lColunasOK
	data oTabela
	data aRotinaIn
	data cErro
	method new() CONSTRUCTOR
	method mostraErro()
	method getAliasTemp()
	method setARotina()
	method getColumn()
	method jukPlay()
EndClass

/*/{Protheus.doc} New
	Metodo construtor da classe
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method New(aCampos, cAliasQuery, cCampoIndice, cCampoSel) class jukMarkBrowse
	local nIx
	local lFalhaIndice	:= .T.
	local lFalhaSel		:= .T.

	::cErro := ""
	::lValidado	:= .F. // Pressupõe que não está verificado
	for nIx := 1 to len(aCampos)
		if len(aCampos[nIx]) != 6 .or. ValType(aCampos[nIx, 1]) != "C" .or. ValType(aCampos[nIx, 2]) != "C" .or. ValType(aCampos[nIx, 3]) != "C" .or. len(aCampos[nIx, 3]) != 1 .or. ValType(aCampos[nIx, 4]) != "N" .or. ValType(aCampos[nIx, 5]) != "N" .or. ValType(aCampos[nIx, 6]) != "C"
			FWAlertError("Array de campos aCampos fora de especificação.", NOME_FONTE)
			::cErro += "Array de campos aCampos fora de especificação." + CRLF
			return
		endIf
		if aCampos[nIx, 1] == cCampoIndice
			lFalhaIndice := .F. // Se pelo menos um dos campos for o campo indice entao ok
		endIf
		if aCampos[nIx, 1] == cCampoSel
			lFalhaSel := .F. // Se pelo menos um dos campos for o campo seletor entao ok
		endIf
	next nIx
	if lFalhaIndice
		FWAlertError("cCampoIndice não existe no array de campos aCampos", NOME_FONTE)
		::cErro += "cCampoIndice não existe no array de campos aCampos" + CRLF
		return
	endIf
	if lFalhaSel
		FWAlertError("cCampoSel não existe no array de campos aCampos.", NOME_FONTE)
		::cErro += "cCampoSel não existe no array de campos aCampos." + CRLF
		return
	endIf
	if select(cAliasQuery) = 0
		FWAlertError("O alias " + cAliasQuery + " não existe.", NOME_FONTE)
		::cErro += "O alias " + cAliasQuery + " não existe." + CRLF
		return
	endIf
	dbSelectArea(cAliasQuery)
	(cAliasQuery)->(dbGoTop())

	::aCampos		:= aCampos
	::cAliasQuery	:= cAliasQuery
	::cAliasTemp	:= ""
	::cCampoIndice	:= cCampoIndice
	::cCampoSel		:= cCampoSel
	::lValidado		:= .T.
	::lColunasOK	:= .F.
	::aRotinaIn		:= {}
return self

/*/{Protheus.doc} getAliasTemp
	Metodo constroe o alias, popula o alias e retorna alias
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method getAliasTemp() class jukMarkBrowse
	local nIx
	local Aux
	local aAux
	local aCamposRed := {} // array de estrutura de campos porem na versão reduzida

	if !::lValidado
		FWAlertError("O objeto não passou pela validação do construtor" + CRLF + ::cErro, NOME_FONTE)
		return
	endIf

	if ::cAliasTemp != ""
		return ::cAliasTemp
	endIf

	for nIx := 1 to len(::aCampos)
		aAux := {}
		aAdd(aAux, ::aCampos[nIx, 1])
		aAdd(aAux, ::aCampos[nIx, 3])
		aAdd(aAux, ::aCampos[nIx, 4])
		aAdd(aAux, ::aCampos[nIx, 5])
		aAdd(aCamposRed, aAux)
	next nIx

	::cAliasTemp := getNextAlias()
	::oTabela := FWTemporaryTable():new(::cAliasTemp, aCamposRed)
	::oTabela:AddIndex("01", {::cCampoIndice} )
	::oTabela:Create()
	::cAliasTemp := ::oTabela:GetAlias()

	// copia dados do alias da query para o alias temporario
	(::cAliasQuery)->(dbGoTop())
	while !(::cAliasQuery)->(eof())
		(::cAliasTemp)->(dbAppend())
		for nIx := 1 to len(::aCampos)
			Aux := &(::cAliasQuery + "->" + ::aCampos[nIx, 1])
			if ::aCampos[nIx, 3] == 'D' .and. valType(Aux) == 'C'
				Aux := sToD(Aux)
			elseIf (::aCampos[nIx, 3] == 'C' .and. valType(Aux) == 'C') .or. (::aCampos[nIx, 3] == 'M' .and. valType(Aux) == 'C')
				Aux := allTrim(Aux)
			elseIf ::aCampos[nIx, 3] != valType(Aux)
				FWAlertError("Erro de tipagem." + CRLF + "Campo " + ::aCampos[nIx, 1] + CRLF + "Esperava receber " + ::aCampos[nIx, 3] + " mas recebeu " + valType(Aux), NOME_FONTE)
				::cErro += "Erro de tipagem." + CRLF + "Campo " + ::aCampos[nIx, 1] + CRLF + "Esperava receber " + ::aCampos[nIx, 3] + " mas recebeu " + valType(Aux) + CRLF
				::lValidado := .F.
				(::cAliasTemp)->(dbCloseArea())
				return
			endIf
			&(::cAliasTemp + "->" + ::aCampos[nIx, 1]) := Aux
		next nIx
		(::cAliasTemp)->(dbCommit())
		(::cAliasQuery)->(dbSkip())
	endDo
	(::cAliasQuery)->(dbGoTop())
	(::cAliasTemp)->(dbGoTop())
return ::cAliasTemp

/*/{Protheus.doc} setARotina
	Metodo seta o array aRotinaIn dentro da classe
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method setARotina(aRotina) class jukMarkBrowse
	if ::cAliasTemp == ""
		FWAlertError("Use o metodo getAliasTemp() antes do setARotina(aRotina) se for necessário incluir o cAliasTemp na chamada de alguma função que esteja no aRotina", NOME_FONTE)
	endIf
	::aRotinaIn := aRotina
return

/*/{Protheus.doc} getColumn
	Metodo constroe as colunas da classe FWBrwColumn
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method getColumn() class jukMarkBrowse
	local oColumn
	local nIx
	local aColunas		:= {}

	if ::cAliasTemp == ""
		::getAliasTemp()
	endIf
	for nIx := 1 to len(::aCampos)
		oColumn := FWBrwColumn():New()
		oColumn:SetData(&("{|| " + ::cAliasTemp + "->" + ::aCampos[nIx,1] +"}"))
		oColumn:SetTitle(::aCampos[nIx,2])
		oColumn:SetType(::aCampos[nIx,3])
		oColumn:SetSize(::aCampos[nIx,4])
		oColumn:SetDecimal(::aCampos[nIx,5])
		oColumn:SetPicture(::aCampos[nIx,6])
		aAdd(aColunas, oColumn)
	next nIx
return aColunas

/*/{Protheus.doc} jukPlay
	Metodo que executa o markBrowse
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method jukPlay() class jukMarkBrowse
	local aColunas
	local oFontGrid

	Private oDlgMark
	Private oPanGrid
	Private oMarkBrowse
	Private aRotina
	Private aMsAdvSize

	aMsAdvSize := MsAdvSize()
	oFontGrid := TFont():New('Tahoma',,-14)
	aColunas := ::getColumn()
	aRotina := menuDef(::aRotinaIn)

	//Criando a janela
	DEFINE MSDIALOG oDlgMark TITLE "Libera��es a enviar para DrivIn" FROM 000, 000  TO aMsAdvSize[6], aMsAdvSize[5] COLORS 0, 16777215 PIXEL
	oPanGrid := tPanel():New(001, 001, '', oDlgMark, , , , RGB(000,000,000), RGB(254,254,254), (aMsAdvSize[5]/2)-1, (aMsAdvSize[6]/2 - 1))
	oMarkBrowse := FWMarkBrowse():New()
	oMarkBrowse:SetDescription("Selecione libera��es a enviar") //Titulo da Janela
	oMarkBrowse:SetAlias(::cAliasTemp)
	oMarkBrowse:oBrowse:SetDBFFilter(.T.)
	oMarkBrowse:oBrowse:SetUseFilter(.F.) //Habilita a utilização do filtro no Browse
	oMarkBrowse:oBrowse:SetFixedBrowse(.T.)
	oMarkBrowse:SetWalkThru(.F.) //Habilita a utilização da funcionalidade Walk-Thru no Browse
	oMarkBrowse:SetAmbiente(.T.) //Habilita a utilização da funcionalidade Ambiente no Browse
	oMarkBrowse:SetTemporary(.T.) //Indica que o Browse utiliza tabela temporária
	//oMarkBrowse:oBrowse:SetSeek(.T.,{{"REGISTRO", {{"", "N", 14, 0, "REGISTRO", "@E 9999999999999"}}}}) //Habilita a utilização da pesquisa de registros no Browse
	oMarkBrowse:oBrowse:SetFilterDefault("") //Indica o filtro padrão do Browse
	oMarkBrowse:SetFieldMark(::cCampoSel)
	oMarkBrowse:SetFontBrowse(oFontGrid)
	oMarkBrowse:SetOwner(oPanGrid)

	oMarkBrowse:AddLegend("C9_DATENT<date()", "BLUE", "Entrega atrasada")
	oMarkBrowse:AddLegend("date()<=C9_DATENT.and.COMUNIC==1", "GREEN", "Apto a enviar")
	oMarkBrowse:AddLegend("COMUNIC==2", "YELLOW", "Enviado")
	oMarkBrowse:AddLegend("date()<=C9_DATENT.and.COMUNIC==4", "RED", "Enviado com erro")
	oMarkBrowse:SetValid({|| date() <= C9_DATENT .and. (COMUNIC == 1 .or. COMUNIC==4)})

	oMarkBrowse:SetColumns(aColunas)
	oMarkBrowse:Activate()
	ACTIVATE MsDialog oDlgMark CENTERED
	//Deleta a temporária e desativa a tela de marcação
	::oTabela:Delete()
	oMarkBrowse:DeActivate()
return

/*/{Protheus.doc} mostraErro
	Metodo que mostra o erro quando chamado pelo desenvolvedor usu'ario da classe
	@type method
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
method mostraErro() class jukMarkBrowse
	msgAlert(::cErro, NOME_FONTE)
return ::cErro

/*/{Protheus.doc} menuDef
	Funcao requesitada pela classe FWMarkBrowse
	@type static function
	@author Julio Carvalho Barberino
	@since 06/05/2026
	@version 0
/*/
static function menuDef(aRotina)
	local aRet := aClone(aRotina)
return aRet
