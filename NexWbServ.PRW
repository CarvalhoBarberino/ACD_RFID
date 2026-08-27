#INCLUDE "protheus.ch"
//#include 'parmtype.ch'
//#include "TOTVS.CH"
#INCLUDE "restful.ch"
//#include "tbiconn.ch"

#DEFINE NOME_FONTE "NexWbServ.PRW"
#DEFINE compEmpre "01" // juk ver se isso ainda eh util

WSRESTFUL nexSolucoes DESCRIPTION "webService com os metodos da NEX Solucoes" // https://tdn.totvs.com/display/public/framework/02.+Criando+uma+classe+REST https://terminaldeinformacao.com/2024/07/13/criando-um-webservice-rest-com-wsrestful-maratona-advpl-e-tl-535/

	WSMETHOD POST apontamento_producao DESCRIPTION "Endpoint Protheus dedicado a receber e registrar apontamentos de producao" PATH "/production_add"
	WSMETHOD POST chamaBlock DESCRIPTION "Endpoint para chamaBlock" PATH "/chamaBlock"

END WSRESTFUL

WSMETHOD POST apontamento_producao WSSERVICE nexSolucoes
	local cConteudo		:= self:getContent()
	local oJsonReceb	:= jsonObject():new()
	local cErroJson		:= oJsonReceb:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	local oJsonRet		:= jsonObject():new() // Json de resposta
	local cFilia
	local cOp			// Ordem de producao
	local cCodProd		// Cod do Produto
	local cDescr		// Descricao do produto
	local cArmazem		// Armazem
	local cLote			// Lote
	local nQuant		// Quantidade
	local cSerie		// Numero de serie do produto
	local cTags			// Tags
	local aExecAut		// Array com retorno do execAuto {lOk, cDetalhes}
	local cRet

	self:SetContentType('aplication/json')

	if !empty(cErroJson)
		self:setStatus(400)
		oJsonRet["erro"] := "Erro ao fazer parse do json, erro ao interpretar arquivo json" + cErroJson + " " + NOME_FONTE
		cRet := oJsonRet:toJson()
		self:setResponse(ENCODEUTF8(cRet))
		self:setStatus(400)
		return .T.
	endIf

	cFilia		:= oJsonReceb:GetJsonObject("filial")
	cOp			:= oJsonReceb:GetJsonObject("op")
	cCodProd	:= oJsonReceb:GetJsonObject("cod_prod")
	cDescr		:= oJsonReceb:GetJsonObject("descricao")
	cArmazem	:= oJsonReceb:GetJsonObject("local")
	cLote		:= oJsonReceb:GetJsonObject("lote")
	nQuant		:= oJsonReceb:GetJsonObject("qtd")
	cSerie		:= oJsonReceb:GetJsonObject("serie")
	cTags		:= oJsonReceb:GetJsonObject("tags")

	BEGIN TRANSACTION
		aExecAut := {.F., "Erro: U_aptProd não terminou"}
		aExecAut := U_aptProd(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
		if !aExecAut[1]
			DisarmTransaction()
			oJsonRet["U_aptProd"] := aExecAut[2]
			oJsonRet["retorno"] := "DisarmTransaction() in U_aptProd"
			cRet := oJsonRet:toJson()
			self:setResponse(ENCODEUTF8(cRet))
			self:setStatus(400)
			return .T.
		endIf
		oJsonRet["U_aptProd"] := aExecAut[2]
		
		aExecAut := {.F., "Erro: U_endereca não terminou"}
		aExecAut := U_endereca(cFilia, cOp, cCodProd, cDescr, cArmazem, cLote, nQuant, cSerie, cTags)
		if !aExecAut[1]
			DisarmTransaction()
			oJsonRet["U_endereca"] := aExecAut[2]
			oJsonRet["retorno"] := "DisarmTransaction() in U_endereca"
			cRet := oJsonRet:toJson()
			self:setResponse(ENCODEUTF8(cRet))
			self:setStatus(400)
			return .T.
		endIf
		oJsonRet["U_endereca"] := aExecAut[2]
	END TRANSACTION

	oJsonRet["retorno"] := aExecAut[2]
	cRet := oJsonRet:toJson()
	self:setResponse(ENCODEUTF8(cRet))
	self:setStatus(201)
return .T.

WSMETHOD POST chamaBlock WSSERVICE nexSolucoes
	local bBlock
	local aParams
	local cRet			:= "texto qualquer 1522"
	local oJson0		:= jsonObject():new()

	oJson0:fromJson(self:getContent())
	bBlock := &(oJson0['bBlock'])
	aParams := &(oJson0['aParams'])

	if valType(bBlock) == "B" .and. valType(aParams) == "A"
		cRet := cValToChar(eval(bBlock, aParams))
	endIf

	self:setResponse(ENCODEUTF8(cRet))
	self:setStatus(201)
return .T.
