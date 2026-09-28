#INCLUDE "protheus.ch"
//#include 'parmtype.ch'
//#include "TOTVS.CH"
#INCLUDE "restful.ch"
//#include "tbiconn.ch"

#DEFINE NOME_FONTE "NexWbServ.PRW"
#DEFINE compEmpre "01" // juk ver se isso ainda eh util

WSRESTFUL nexSolucoes DESCRIPTION "webService com os metodos da NEX Solucoes" // https://tdn.totvs.com/display/public/framework/02.+Criando+uma+classe+REST https://terminaldeinformacao.com/2024/07/13/criando-um-webservice-rest-com-wsrestful-maratona-advpl-e-tl-535/

	WSMETHOD POST apontamento_producao DESCRIPTION "Endpoint Protheus dedicado a receber e registrar apontamentos de producao" PATH "/production_add"
	WSMETHOD POST saida_produto DESCRIPTION "Endpoint PROTHEUS dedicado a receber faturas que passaram no portal de saída expedição." PATH "/outbound_sell"
	WSMETHOD POST transffil_out DESCRIPTION "Protheus recebe aviso de saída de produtos com destino a outra filial. Processo disparado na filial de origem." PATH "/transf_fil/out"
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
		aExecAut := {.F., "Erro: U_aptProd nÃ£o terminou"}
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

		aExecAut := {.F., "Erro: U_endereca nÃ£o terminou"}
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

WSMETHOD POST saida_produto WSSERVICE nexSolucoes // 1.2.2.2.4.2
	local cConteudo		:= self:getContent()
	local oJsonIn		:= jsonObject():new()
	local cErroJson		:= oJsonIn:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	local oJsonOut		:= jsonObject():new() // Json de resposta
	local nFat, cFilia, cFatura, cFatSerie, cCliente, cProduto, cItem, cTag

/* Exemplo de json que espera receber
{
  "facturas": [
    {
      "filial": "01",
      "fatura": "0300010035585",
      "fat_serie": "S1",
      "cliente": "1234567890001",
      "itens": [
        {
          "item": "1",
          "pedido": "AACSJW",
          "ordsep": "000006",
          "cod_prod": "ABSNKR100190",
          "lote": "AAEIMA0100",
          "numserie": "000119",
          "qtd": 1,
          "tag": "300862D3D18BE4588BF15F48"
        }
      ]
    }
  ]
}
*/
	dbSelectArea("SD2")
	SD2->(dbSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	for nFat := 1 to len(oJsonIn['facturas'])
		cFilia := oJsonIn['facturas'][nFat]['filial']
		cFatura := oJsonIn['facturas'][nFat]['fatura']
		cFatSerie := oJsonIn['facturas'][nFat]['fat_serie']
		cCliente := oJsonIn['facturas'][nFat]['cliente']
		for nItem := 1 to len(oJsonIn['facturas'][nFat]['itens'])
			cProduto := oJsonIn['facturas'][nFat]['itens'][nItem]['cod_prod']
			cItem := oJsonIn['facturas'][nFat]['itens'][nItem]['item']
			cTag := oJsonIn['facturas'][nFat]['itens'][nItem]['tag']
			SD2->(dbGoTop())
			if SD2->(msSeek(cFilia + cFatura + cFatSerie + cCliente + cProduto + cItem))
				recLock("SD2", .F.)
				SD2->D2_ZB0COD := cTag
				SD2->(msUnLock())
			endIf
		next nItem
	next nFat
return .T.

WSMETHOD POST transffil_out WSSERVICE nexSolucoes
	local cConteudo		:= self:getContent()
	local oJsonIn		:= jsonObject():new()
	local cErroJson		:= oJsonIn:fromJson(cConteudo) // Variavel que indica se houve erro na interpretacao do json
	local oJsonOut		:= jsonObject():new() // Json de resposta
	local cFilOri		:= oJsonIn['FilOrig']
	local cFilDest		:= oJsonIn['FilDest']
	local aItens		:= {}
	local aItem, nI
/* Exemplo de json que espera receber
{
  "OrdemSaidaNum:": "000154",
  "FilOrig": "01",
  "FilDest": "02",
  "Itens": [
    {
      "CodProd": "0001546",
      "Qtd": 45,
      "Local": "01",
      "Lote": "001546",
      "SerialNumber": "0004687",
      "Endereco": "0048765"
    },
    {
      "CodProd": "0001616",
      "Qtd": 95,
      "Local": "01",
      "Lote": "001547",
      "SerialNumber": "0004688",
      "Endereco": "0048740"
    }
  ]
}
*/
for nI := 1 to len(oJsonIn['Itens'])
	aItem := {oJsonIn['CodProd'], oJsonIn['Qtd'], oJsonIn['Local'], oJsonIn['Lote'], oJsonIn['SerialNumber'], oJsonIn['Endereco']}
	aAdd(aItens, aItem)
next nI

	
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
