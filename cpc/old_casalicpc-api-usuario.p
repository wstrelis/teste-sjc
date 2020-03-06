
/*------------------------------------------------------------------------
    File        : cpc-api-usuario.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Tue Jun 06 08:18:56 BRT 2017
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */



define temp-table temp-eventos      no-undo
    field in-evento                 as   integer
    field in-evento-pagamento       as   integer
    field dc-proporcao              as   decimal
    field dc-valor-evento           as   decimal.
    

define temp-table temp-valor-evento no-undo
    field in-evento                 as   integer
    field dc-valor                  as   decimal.
    
define temp-table temp-estruturas-participantes no-undo
    field in-modalidade             as   integer.
    
    
define new shared variable c-versao         as character    format "x(08)"                
                                                                        no-undo.
    
define variable PARAM_ESPECIE_TITULO_ACP    as   character  init "CPR"  no-undo.    
define variable PARAM_GRUPO_FORNECEDOR      as   integer    init 95     no-undo.
define variable PARAM_CONTA_CONTABIL        as   character  init '2188890880018'
                                                                        no-undo.


define new global shared variable v_cod_usuar_corren as character
                          format "x(12)":U label "Usu†rio Corrente"
                                        column-label "Usu†rio Corrente" no-undo. 
                                        
empty temp-table temp-eventos.
create temp-eventos.
assign temp-eventos.in-evento           = 622
       temp-eventos.dc-proporcao        = 50.

create temp-eventos.
assign temp-eventos.in-evento           = 623
       temp-eventos.dc-proporcao        = 30.

create temp-eventos.
assign temp-eventos.in-evento           = 624
       temp-eventos.dc-proporcao        = 20.
                                        
{utils/dates.i}

{api/api-usuario.i}.
{cpc/cpc-api-usuario.i}
{ppp/pp0410x.i}
{ppp/pp0410f.i} 
/*{rtp/rtapi044.i}*/
{srincl/srplano.iv}

{hdp/hdrunpersis.iv "new"}
{rtp/rtrowerror.i}                                        
                                        
if v_cod_usuar_corren = ?
or v_cod_usuar_corren = ""
then v_cod_usuar_corren = "super".                                        

/* ********************  Preprocessor Definitions  ******************** */

/* ************************  Function Prototypes ********************** */


function BuscaNumeroTituloEMS returns character 
	(  ) forward.

function BuscaValorProporcao returns logical 
	(  ) forward.

function CalcularValorDevolucao returns decimal 
	(in-ano             as   integer,
	 in-mes             as   integer,
	 dt-exclusao-plano  as   date) forward.

function CriaEventoProgramado returns logical 
	(dt-exclusao-plano     as   date) forward.

function EhUltimoBeneficiarioTermo returns logical 
	(dt-exclusao-plano as date) forward.

function EstruturasParticipantes returns logical 
    (  ) forward.

function ExcluirBeneficiarioFaturamentoPosterior returns logical 
	(  ) forward.

function ImplantarTituloFinanceiro returns logical 
	(in-ano as integer,
	 in-mes as integer) forward.

function RegistraEstrutura returns logical 
    (in-modalidade          as   integer) forward.

/* ***************************  Main Block  *************************** */

/* ************************  Function Implementations ***************** */


function BuscaNumeroTituloEMS returns character 
	(  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

    define variable in-numero-titulo as integer no-undo.
    
    find last tit_ap no-lock 
    use-index titap_id
        where tit_ap.cod_estab          = paramecp.cod-estabel
          and tit_ap.cdn_fornecedor     = preserv.cd-contratante
          and tit_ap.cod_espec_docto    = PARAM_ESPECIE_TITULO_ACP
          and tit_ap.cod_tit_ap        <> ""
          and tit_ap.cod_parcela        = "01" 
              no-error.
              
    if available tit_ap
    then do:
        assign in-numero-titulo     = integer (tit_ap.cod_tit_ap) no-error.
    end.
                                
    do while available tit_ap or in-numero-titulo = 0:
        
        assign in-numero-titulo     = in-numero-titulo + 1.
        
        find last tit_ap no-lock 
        use-index titap_id
            where tit_ap.cod_estab          = paramecp.cod-estabel
              and tit_ap.cdn_fornecedor     = preserv.cd-contratante
              and tit_ap.cod_espec_docto    = PARAM_ESPECIE_TITULO_ACP
              and tit_ap.cod_tit_ap         = string (in-numero-titulo)
              and tit_ap.cod_parcela        = "01" 
                  no-error.
    end.

    return string (in-numero-titulo).
		
end function.

function BuscaValorProporcao returns logical 
	(  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/	

    define variable dc-proporcao-total      as   decimal        no-undo.
    
    for each temp-eventos:        
        assign dc-proporcao-total       = dc-proporcao-total + temp-eventos.dc-proporcao.
        
        /**
         * Caso a proporá∆o do evento tenha sido definida no fonte
         * quando atribu°do os eventos do desconto, n∆o busca o percentual 
         * na estrutura e utiliza o que esta definido na tabela.
         */         
        if temp-eventos.dc-proporcao   <> 0 then next.
        
        for first tipleven no-lock
            where tipleven.cd-modalidade    = propost.cd-modalidade
              and tipleven.cd-plano         = propost.cd-plano
              and tipleven.cd-tipo-plano    = propost.cd-tipo-plano
              and tipleven.cd-forma-pagto   = propost.cd-forma-pagto
              and tipleven.in-entidade      = "FT"             
              and tipleven.cd-evento        = temp-eventos.in-evento
              and tipleven.lg-ativo         = yes:
                 
            assign temp-eventos.dc-proporcao    = tipleven.pc-princ-aux
                   dc-proporcao-total           = dc-proporcao-total + temp-eventos.dc-proporcao.            
        end.                  
    end.
    
    if dc-proporcao-total   <> 100 
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Proporá∆o dos eventos de desconto Ç diferente de 100%".
        return no.               
    end.
    return yes.
end function.


function CalcularValorDevolucao returns decimal 
	(in-ano             as   integer,
     in-mes             as   integer,
     dt-exclusao-plano  as   date ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable in-quantidade-dias-periodo      as   integer        no-undo.
    define variable in-quantidade-dias-cobertura    as   integer        no-undo.
    define variable dt-inicial                      as   date           no-undo.
    define variable dt-final                        as   date           no-undo.
    define variable in-contratante-nota-serv        as   integer        no-undo.
    define variable dc-valor-mensalidade            as   decimal        no-undo.
    define variable dc-valor-devolver               as   decimal        no-undo.
    define variable in-evento                       like evenfatu.cd-evento
                                                                        no-undo.
    define variable in-mes-cobertura                as   integer        no-undo.
    define variable in-ano-cobertura                as   integer        no-undo.
    define variable in-dia-mes                      as   integer        no-undo.                                                                        
                                                                            
    find first modalid no-lock   
         where modalid.cd-modalidade     = propost.cd-modalidade.
     
    if modalid.in-tipo-pessoa       = "J"
    or (    modalid.in-tipo-pessoa  = "F"
        and propost.dt-parecer      < 03/15/2015)
    then do:
        assign in-quantidade-dias-periodo   = DiasNoMes (in-ano, in-mes)
               dt-inicial                   = date (in-mes, 1, in-ano)
               dt-final                     = UltimoDiaMes (in-ano, in-mes).
    end.
    else do:       
        /**
         * Tratavida do calendario de vendas, onde o cliente paga/tem direito a 
         * usufruir o plano sempre com base na data de anivers†rio do contrato 
         */              
        assign in-ano-cobertura             = in-ano
               in-mes-cobertura             = in-mes + 1.
        
        if in-mes-cobertura                 > 12
        then assign in-mes-cobertura        = 1
                    in-ano-cobertura        = in-ano-cobertura + 1.               
        
        assign in-dia-mes  = day (propost.dt-parecer).
        do while true:
            
            assign dt-final     = date (in-mes-cobertura, in-dia-mes, in-ano-cobertura) no-error.
            if not error-status:error
            then leave.
            
            in-dia-mes = in-dia-mes - 1.
        end. 
        
        assign dt-inicial                   = add-interval (dt-final, -1, "month") + 1
               in-quantidade-dias-periodo   = interval (dt-final, dt-inicial, "days") + 1.   
    end.    
    
    assign in-quantidade-dias-cobertura     = interval (dt-exclusao-plano, dt-inicial, "days") + 1.
    
    if in-quantidade-dias-cobertura     > in-quantidade-dias-periodo
    then in-quantidade-dias-cobertura   = in-quantidade-dias-periodo.
    
    message "data inicial periodo:" + string (dt-inicial, "99/99/9999") skip 
            "data final periodo:" + string (dt-final, "99/99/9999") skip
            "quantidade dias periodo: " + string (in-quantidade-dias-periodo) skip
            "quantidade dias cobetura: " + string (in-quantidade-dias-cobertura).
                           
                        
    for each notaserv no-lock
       where notaserv.cd-modalidade             = propost.cd-modalidade
         and notaserv.cd-contratante            = propost.cd-contratante
         and notaserv.cd-contratante-origem     = propost.nr-insc-contrat-origem
         and notaserv.nr-ter-adesao             = propost.nr-ter-adesao
         and date (notaserv.mm-referencia, 1, notaserv.aa-referencia) >= date (in-mes, 1, in-ano):
                          
        message substitute ("lendo nota &1/&2/&3/&4/&5/&6 ",
                            notaserv.cd-modalidade,        
                            notaserv.cd-contratante,       
                            notaserv.cd-contratante-origem,
                            notaserv.nr-ter-adesao,        
                            notaserv.aa-referencia,        
                            notaserv.mm-referencia).
                            

        find first fatura no-lock
             where fatura.cd-contratante        = notaserv.cd-contratante                
               and fatura.nr-fatura             = notaserv.nr-fatura
                   no-error.
                   
        if not available fatura
        then next.

        find first tit_acr no-lock  
             where tit_acr.cod_estab       = fatura.cod-estabel
               and tit_acr.cod_espec_docto = fatura.cd-especie
               and tit_acr.cod_ser_docto   = substring (fatura.serie-nf, 1, 3)
               and tit_acr.cod_tit_acr     = fatura.nr-titulo-acr
               and (   string (int(tit_acr.cod_parcela), '99')  =  string (fatura.parcela, "99")
                    or (    fatura.parcela   = 0
                        and tit_acr.cod_parcela = ''
                        ))
                   no-error.    
        
        if not available tit_acr
        then next.
        
        if tit_acr.val_sdo_tit_acr = 0
        then next.                  

        for each vlbenef no-lock
           where vlbenef.cd-modalidade          = notaserv.cd-modalidade        
             and vlbenef.cd-contratante         = notaserv.cd-contratante       
             and vlbenef.cd-contratante-origem  = notaserv.cd-contratante-origem
             and vlbenef.nr-ter-adesao          = notaserv.nr-ter-adesao        
             and vlbenef.aa-referencia          = notaserv.aa-referencia        
             and vlbenef.mm-referencia          = notaserv.mm-referencia        
             and vlbenef.nr-sequencia           = notaserv.nr-sequencia         
             and vlbenef.cd-usuario             = usuario.cd-usuario:
                 
            find first evenfatu no-lock
                 where evenfatu.in-entidade     = "FT"
                   and evenfatu.cd-evento       = vlbenef.cd-evento.    

            assign in-evento    = if evenfatu.cd-evento-impressao = 0 then evenfatu.cd-evento else evenfatu.cd-evento-impressao.
            
            message substitute ("lendo evento &1 valor &2 tipo &3",
                                vlbenef.cd-evento,
                                vlbenef.vl-usuario,
                                evenfatu.in-classe-evento).     
             
            if evenfatu.in-classe-evento    = "A"
            or evenfatu.in-classe-evento    = "K"
            or evenfatu.in-classe-evento    = "L"
            or evenfatu.in-classe-evento    = "N"
            or evenfatu.in-classe-evento    = "O"
            or evenfatu.in-classe-evento    = "P"
            or evenfatu.in-classe-evento    = "Q"
            or evenfatu.in-classe-evento    = "W"
            or evenfatu.in-classe-evento    = "4"
            then do:
                
                assign dc-valor-mensalidade = dc-valor-mensalidade + vlbenef.vl-usuario.
                message substitute ("valor considerado: &1", dc-valor-mensalidade). 
            end.                                                         
        end.                 
    end.             
    
    assign dc-valor-devolver    = round (dc-valor-mensalidade - ((dc-valor-mensalidade / in-quantidade-dias-periodo) * in-quantidade-dias-cobertura), 2). 

    message substitute ("valor devolver: &1", dc-valor-devolver).
    
    return dc-valor-devolver.
end function.

function CriaEventoProgramado returns logical 
	 (dt-exclusao-plano     as   date):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

    define variable dc-valor-desconto       as   decimal                    no-undo.
    define variable dc-saldo                as   decimal                    no-undo.
    
    /* Màs/ano para registrar o evento do pr¢xima faturamento */
    define variable in-ano-proximo-fatu     as   integer                    no-undo.
    define variable in-mes-proximo-fatu     as   integer                    no-undo.


/** 
 * CASO OPTEM POR JOGAR O EVENTO CONTRA O TITULAR DO PLANO,
 * DECONOMENTAR BLOCO ABAIXO 
 */          
/*    if usuario.cd-titular   <> 0                           */
/*    then do:                                               */
/*        assign in-usuario   = usuario.cd-titular.          */
/*                                                           */
/*        find first usuario no-lock                         */
/*             where usuario.cd-modalidade    = in-modalidade*/
/*               and usuario.nr-proposta      = in-proposta  */
/*               and usuario.cd-usuario       = in-usuario.  */
/*    end.                                                   */

    if not BuscaValorProporcao() then return no.

    assign dc-valor-desconto    = CalcularValorDevolucao (usuario.aa-ult-fat,  
                                                          usuario.mm-ult-fat, 
                                                          dt-exclusao-plano).
    /** 
     * N∆o possui valor para descontar
     */
    if dc-valor-desconto = 0 then return yes.
                           
    assign dc-saldo = dc-valor-desconto.
        
    for each temp-eventos:
        
        assign temp-eventos.dc-valor-evento = round ((dc-valor-desconto * temp-eventos.dc-proporcao) / 100, 2)
               dc-saldo                     = dc-saldo - temp-eventos.dc-valor-evento.       
               message substitute ("valor do evento rateado: &1/&2",
                                   temp-eventos.in-evento,
                                   temp-eventos.dc-valor-evento).
    end.
    
    if dc-saldo <> 0
    then do:
        find last temp-eventos.
        assign temp-eventos.dc-valor-evento = temp-eventos.dc-valor-evento + dc-saldo.
    end.
    
    assign in-mes-proximo-fatu  = usuario.mm-ult-fat
           in-ano-proximo-fatu  = usuario.aa-ult-fat
           in-mes-proximo-fatu  = in-mes-proximo-fatu + 1.
           
    if in-mes-proximo-fatu > 12 
    then do:
        assign in-mes-proximo-fatu  = 1
               in-ano-proximo-fatu  = in-ano-proximo-fatu + 1.
    end.       
    
    message substitute ("mes/ano proxima fatura: &1/&2",
                        in-mes-proximo-fatu,
                        in-ano-proximo-fatu).
    
    for each temp-eventos:
        
        message substitute ("lendo evento &1/&2/&3",
                            temp-eventos.in-evento,
                            temp-eventos.dc-proporcao,
                            temp-eventos.dc-valor-evento).
        
        find first evenfatu 
             where evenfatu.in-entidade = "FT"
               and evenfatu.cd-evento   = temp-eventos.in-evento
               no-lock no-error.
               
        if not available evenfatu
        then do:
            assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
                   tmp-cpc-api-usuario-saida.ds-mensagem-erro   = substitute ("Evento &1 n∆o cadastrado.",temp-eventos.in-evento).
            return no.            
        end.                        
        
        find first event-progdo-bnfciar exclusive-lock
             where event-progdo-bnfciar.cd-modalidade   = usuario.cd-modalidade        
               and event-progdo-bnfciar.nr-ter-adesao   = propost.nr-ter-adesao
               and event-progdo-bnfciar.cd-usuario      = usuario.cd-usuario           
               and event-progdo-bnfciar.aa-referencia   = in-ano-proximo-fatu               
               and event-progdo-bnfciar.mm-referencia   = in-mes-proximo-fatu               
               and event-progdo-bnfciar.cd-evento       = temp-eventos.in-evento 
                   no-error.
    
        if not available event-progdo-bnfciar
        then do:
            
            create event-progdo-bnfciar.
            assign event-progdo-bnfciar.cd-modalidade           = usuario.cd-modalidade
                   event-progdo-bnfciar.nr-ter-adesao           = propost.nr-ter-adesao
                   event-progdo-bnfciar.cd-usuario              = usuario.cd-usuario
                   event-progdo-bnfciar.aa-referencia           = in-ano-proximo-fatu
                   event-progdo-bnfciar.mm-referencia           = in-mes-proximo-fatu
                   event-progdo-bnfciar.cd-evento               = temp-eventos.in-evento
                   event-progdo-bnfciar.cd-moeda                = 0
                   event-progdo-bnfciar.cod-usuar-ult-atualiz   = v_cod_usuar_corren.               
        end.               
    	
        assign event-progdo-bnfciar.qt-evento       = 1
               event-progdo-bnfciar.dat-ult-atualiz = today
               event-progdo-bnfciar.vl-evento       = temp-eventos.dc-valor-evento. 
    end.

    if EhUltimoBeneficiarioTermo (dt-exclusao-plano)
    then do:
        ImplantarTituloFinanceiro (in-ano-proximo-fatu, in-mes-proximo-fatu).
/*        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = no                                                                                                                 */
/*               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = substitute ("Benefici†rio Ç o £ltimo benefici†rio do termo e n∆o poder† ser exclu°do pois possui valor a receber").*/
/*        return no.                                                                                                                                                               */
    end.     

    
end function.

function EhUltimoBeneficiarioTermo returns logical 
	(dt-exclusao-plano as date   ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define buffer buf-usuario for usuario .

    find first buf-usuario no-lock
         where buf-usuario.cd-modalidade            = usuario.cd-modalidade
           and buf-usuario.nr-proposta              = usuario.nr-proposta
           and buf-usuario.cd-usuario              <> usuario.cd-usuario
           and (   buf-usuario.dt-exclusao-plano    = ?
                or buf-usuario.dt-exclusao-plano   <> buf-usuario.dt-inclusao-plano)
           and (   buf-usuario.dt-exclusao-plano    = ?
                or buf-usuario.dt-exclusao-plano    > dt-exclusao-plano)
           and buf-usuario.cd-sit-usuario          <= 7
               no-error.
               
    return not available buf-usuario.
end function.

function EstruturasParticipantes returns logical 
    (  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    


        
end function.

function ExcluirBeneficiarioFaturamentoPosterior returns logical 
	(  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable dt-faturamento      as   date                   no-undo.
    define variable dt-exclusao         as   date                   no-undo.
    define variable in-ano              as   integer                no-undo.
    define variable in-mes              as   integer                no-undo.
    define variable in-contratante      like contrat.cd-contratante no-undo.

    assign dt-exclusao      = date (month (tmp-cpc-api-usuario-entrada.dt-exclusao-plano), 
                                    1, 
                                    year (tmp-cpc-api-usuario-entrada.dt-exclusao-plano))
           dt-faturamento   = date (tmp-cpc-api-usuario-entrada.mm-ult-faturamento,
                                    1,
                                    tmp-cpc-api-usuario-entrada.aa-ult-faturamento) no-error.                                
                                        
    if error-status:error
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Data de ultimo faturamento nao informada".
        return no.         
    end.
    
    find first propost no-lock
         where rowid (propost)  = tmp-cpc-api-usuario-entrada.r-propost.
         
    find first usuario no-lock
         where rowid (usuario)  = tmp-cpc-api-usuario-entrada.r-usuario.
         
    find first ter-ade no-lock
         where ter-ade.cd-modalidade    = propost.cd-modalidade
           and ter-ade.nr-ter-adesao    = propost.nr-ter-adesao.           
    
    case ter-ade.in-contratante-mensalidade:
        when 1 
        then do:
            assign in-contratante   = propost.nr-insc-contrat-origem.            
        end.
                                    
        when 0 
        then do:
            assign in-contratante   = propost.nr-insc-contratante.
        end.  
    end case.
               
    find first contrat no-lock
         where contrat.nr-insc-contratante  = in-contratante.            
           
    if dt-faturamento >= dt-exclusao
    then do:
        CriaEventoProgramado (tmp-cpc-api-usuario-entrada.dt-exclusao-plano).
        return yes.
    end.
end function.

function ImplantarTituloFinanceiro returns logical 
	(in-ano as integer,
	 in-mes as integer ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    define variable dc-valor-total-titulo           as   decimal        no-undo.
    define variable ch-referencia                   as   character      no-undo.
    define variable hd-api-forncedor                as   handle         no-undo.
    define variable in-fornecedor                   as   integer        no-undo.
    define variable ch-mensagem-erro                as   character      no-undo.

    find first paramecp no-lock.
        
    assign ch-referencia    = replace (replace (replace (string (now, "99/99/99 HH:MM"), "/", ""), ":", ""), " ", "").
    
    empty temp-table temp-valor-evento.
    
    for each temp-eventos:	
        
        for each event-progdo-bnfciar exclusive-lock
           where event-progdo-bnfciar.cd-modalidade     = propost.cd-modalidade        
             and event-progdo-bnfciar.nr-ter-adesao     = propost.nr-ter-adesao
             and event-progdo-bnfciar.cd-usuario       <> 0           
             and event-progdo-bnfciar.aa-referencia     = in-ano               
             and event-progdo-bnfciar.mm-referencia     = in-mes               
             and event-progdo-bnfciar.cd-evento         = temp-eventos.in-evento:
            
            find first temp-valor-evento
                 where temp-valor-evento.in-evento  = temp-eventos.in-evento
                       no-error.
            
            if not available temp-valor-evento
            then do:
                create temp-valor-evento.
                assign temp-valor-evento.in-evento  = temp-eventos.in-evento.
            end.                                   
            
            assign dc-valor-total-titulo        = event-progdo-bnfciar.vl-evento
                   temp-valor-evento.dc-valor   = temp-valor-evento.dc-valor + event-progdo-bnfciar.vl-evento.                  
                   
        end.
    end.
    
    find first fornecedor no-lock 
         where fornecedor.cod_empresa    = trim (string (paramecp.ep-codigo))
           and fornecedor.cdn_fornecedor = contrat.cd-contratante 
               no-error. /*Busca pelo c¢digo do contratante*/
               
    if not available fornecedor
    then do:
        find first fornecedor no-lock  
             where fornecedor.cod_empresa   = trim (string (paramecp.ep-codigo))
               and fornecedor.cod_id_feder  = contrat.nr-cgc-cpf
                   no-error. /*busca pelo Cpf*/
    end.                   
    
    if not available fornecedor 
    then do:
        
        empty temp-table rowErrors.                  
                                 
        {hdp/hdrunpersis.i "dep/de-api-cria-fornecedor.p" "hd-api-forncedor"}
        
        run gera-fornecedor in hd-api-forncedor (input contrat.cd-contratante,
                                                 input PARAM_GRUPO_FORNECEDOR,
                                                 output in-fornecedor,
                                                 input-output table rowErrors).
        {hdp/hddelpersis.i}
        if containsAnyError(input table rowErrors)
        then do:
            for each rowErrors:
                if ch-mensagem-erro <> "" then assign ch-mensagem-erro = ch-mensagem-erro + chr(13).
                
                assign ch-mensagem-erro = ch-mensagem-erro + string (rowErrors.errorNumber) + " - " + rowErrors.errorDescription.
            end.
            assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
                   tmp-cpc-api-usuario-saida.lg-continua        = no
                   tmp-cpc-api-usuario-saida.ds-mensagem-erro   = ch-mensagem-erro.
            message "erro: " + tmp-cpc-api-usuario-saida.ds-mensagem-erro.
            return no.                        
        end.     
        
        find first fornecedor no-lock 
             where fornecedor.cod_empresa    = trim (string (paramecp.ep-codigo))
               and fornecedor.cdn_fornecedor = in-fornecedor.
    end.
    
    
    define variable in-sequencia            as   integer    no-undo.
    in-sequencia = 0.
    
/*    assign in-funcao-rtapi044-aux           = "GDT"                    */
/*           in-tipo-emitente-rtapi044-aux    = "PRESTA"                 */
/*           cd-contratante-rtapi044-aux      = fornecedor.cdn_fornecedor*/
/*           in-tipo-pessoa-rtapi044-aux      = contrat.in-tipo-pessoa.  */
/*                                                                       */
/*    run rtapi044 no-error.                                             */
/*                                                                                                                         */
/*    /*-----------------------------------------------*                                                                   */
/*     * O comando abaixo e para tratar control C no   *                                                                   */
/*     * programa rtapi044 e para tratar erros fora    *                                                                   */
/*     * do processo (anormais).                       *                                                                   */
/*     *-----------------------------------------------*/                                                                  */
/*    if  error-status:error                                                                                               */
/*    and error-status:num-messages = 0                                                                                    */
/*    then do:                                                                                                             */
/*        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes                                                        */
/*               tmp-cpc-api-usuario-saida.lg-continua        = no                                                         */
/*               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Exportacao Titulo foi cancelado pelo usuario do sistema.".*/
/*                                                                                                                         */
/*        return no.                                                                                                       */
/*    end.                                                                                                                 */
/*                                                                                                                         */
/*    if lg-erro-rtapi044-aux                                                                                              */
/*    then do:                                                                                                             */
/*        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes                                                        */
/*               tmp-cpc-api-usuario-saida.lg-continua        = no                                                         */
/*               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Fornecedor "                                              */
/*                                                   + string(titupres.cd-contratante,"99999999")                          */
/*                                                   + " nao cadastrado para Unidade prestador "                           */
/*                                                   + string(titupres.cd-unidade-prestador,"9999")                        */
/*                                                   + " Prestador "                                                       */
/*                                                   + string(titupres.cd-prestador,"99999999").                           */
/*        next.                                                                                                            */
/*    end.                                                                                                                 */
        
    define variable ch-numero-titulo as character no-undo.
    define variable lg-erro as log no-undo.
    define variable ch-erro as character no-undo.
    
                                      
    if error-status:error 
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "erro buscar numero titulo: " + error-status:get-message (1).
    
        message "erro: " + tmp-cpc-api-usuario-saida.ds-mensagem-erro.
    
    end.

    if lg-erro
    or error-status:error 
    then do:            
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "xxxerro buscar numero titulo: " + error-status:get-message (1).
        
        message "erro: " + tmp-cpc-api-usuario-saida.ds-mensagem-erro.    
    end.                                  
    
        
    create tt_integr_apb_lote_impl.
    assign tt_integr_apb_lote_impl.tta_cod_estab                = paramecp.cod-estabel
           tt_integr_apb_lote_impl.tta_cod_refer                = ch-referencia
           tt_integr_apb_lote_impl.tta_dat_transacao            = today
           tt_integr_apb_lote_impl.tta_ind_origin_tit_ap        = "GPS"
           tt_integr_apb_lote_impl.tta_cod_empresa              = string (paramecp.ep-codigo)
           tt_integr_apb_lote_impl.tta_val_tot_lote_impl_tit_ap = dc-valor-total-titulo.    
    create tt_integr_apb_item_lote_impl_3.
    assign tt_integr_apb_item_lote_impl_3.ttv_rec_integr_apb_lote_impl  = recid(tt_integr_apb_lote_impl)
           tt_integr_apb_item_lote_impl_3.ttv_rec_integr_apb_item_lote  = recid(tt_integr_apb_item_lote_impl_3)
           in-sequencia                                                 = in-sequencia + 10
           tt_integr_apb_item_lote_impl_3.tta_num_seq_refer             = in-sequencia
           tt_integr_apb_item_lote_impl_3.tta_cdn_fornecedor            = fornecedor.cdn_fornecedor
           tt_integr_apb_item_lote_impl_3.tta_cod_espec_docto           = PARAM_ESPECIE_TITULO_ACP
           tt_integr_apb_item_lote_impl_3.tta_cod_ser_docto             = ""
           tt_integr_apb_item_lote_impl_3.tta_cod_tit_ap                = BuscaNumeroTituloEMS()
           tt_integr_apb_item_lote_impl_3.tta_cod_parcela               = string (1,"99")           
           tt_integr_apb_item_lote_impl_3.tta_dat_emis_docto            = today           
           tt_integr_apb_item_lote_impl_3.tta_dat_vencto_tit_ap         = add-interval (today, 3, "days")           
           tt_integr_apb_item_lote_impl_3.tta_dat_prev_pagto            = tt_integr_apb_item_lote_impl_3.tta_dat_vencto_tit_ap
           tt_integr_apb_item_lote_impl_3.tta_cod_indic_econ            = "Real"
           tt_integr_apb_item_lote_impl_3.tta_cod_portador              = '12341'
/*           tt_integr_apb_item_lote_impl_3.tta_cod_portador              = string(tmp-rtapi044.portador)*/
           tt_integr_apb_item_lote_impl_3.tta_des_text_histor           = "Documento implantado para atender a legislaá∆o (RN412 - Devoluá∆o mensalidade prÇ paga), na data " +
                                                                          string (today, "99/99/9999")
           tt_integr_apb_item_lote_impl_3.ttv_qtd_parc_tit_ap           = 1
           tt_integr_apb_item_lote_impl_3.ttv_ind_vencto_previs         = ""
           tt_integr_apb_item_lote_impl_3.ttv_log_gerad                 = no
           tt_integr_apb_item_lote_impl_3.tta_cod_cart_bcia             = '1'
/*           tt_integr_apb_item_lote_impl_3.tta_cod_cart_bcia             = string (tmp-rtapi044.modalidade)*/
           tt_integr_apb_item_lote_impl_3.tta_val_tit_ap                = dc-valor-total-titulo.         
/*    {srincl/srplano.i year(today)        */
/*                      month(today)       */
/*                      paramecp.ep-codigo}*/
                      
         assign dt-fim-validade-aux = if month(today) = 12
                                      then date(01, 01, year(today) + 1)  - 1
                                      else date(month(today) + 1, 01, year(today)) - 1
                dt-ini-validade-srems = ?
                dt-fim-validade-srems = ?.
         /* plano de contas */
         assign lg-plano-empresa-ems5 = no
                ds-plano-contas-ems5  = "".
          find first plano_cta_unid_organ no-lock  
               where trim(plano_cta_unid_organ.cod_unid_organ)         = trim (string (paramecp.ep-codigo))
                 and trim(plano_cta_unid_organ.ind_tip_plano_cta_ctbl) = "Primario" 
                 and plano_cta_unid_organ.dat_inic_valid              <= dt-fim-validade-aux
                 and plano_cta_unid_organ.dat_fim_valid               >= dt-fim-validade-aux
                     no-error.
         if not avail plano_cta_unid_organ
         then lg-plano-empresa-ems5 = no.
         else assign lg-plano-empresa-ems5 = yes
                     ds-plano-contas-ems5  = plano_cta_unid_organ.cod_plano_cta_ctbl
                     dt-ini-validade-srems = plano_cta_unid_organ.dat_inic_valid 
                     dt-fim-validade-srems = plano_cta_unid_organ.dat_fim_valid.
    if not lg-plano-empresa-ems5
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Nao existe Plano de contas valido relacionado a empresa: " + 
                                                              string(paramecp.ep-codigo) .
        return no.                                                              
    end.

    
    find first estunemp no-lock  
         where estunemp.cod-estabel = paramecp.cod-estabel
               no-error.    
    if not available estunemp
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Estabelecimento x Unidade de Negocio nao cadastrado".
        return no.               
    end.

/*    for each temp-valor-evento:                                           */
/*                                                                          */
/*        find first temp-eventos                                           */
/*             where temp-eventos.in-evento   = temp-valor-evento.in-evento.*/
/*                                                                          */
/*        find first evencopp                                                   */
/*             where evencopp.cd-evento       = temp-eventos.in-evento-pagamento*/
/*                   no-error.                                                  */ 
                   
        create tt_integr_apb_aprop_ctbl_pend.
        assign tt_integr_apb_aprop_ctbl_pend.ttv_rec_integr_apb_item_lote   = recid (tt_integr_apb_item_lote_impl_3)
               tt_integr_apb_aprop_ctbl_pend.tta_cod_plano_cta_ctbl         = ds-plano-contas-ems5
/*               tt_integr_apb_aprop_ctbl_pend.tta_cod_cta_ctbl               = evencopp.ct-codigo*/
               tt_integr_apb_aprop_ctbl_pend.tta_cod_cta_ctbl               = "4421190190042"                                    
               tt_integr_apb_aprop_ctbl_pend.tta_cod_unid_negoc             = estunemp.cd-unidade-negocio
               tt_integr_apb_aprop_ctbl_pend.tta_cod_plano_ccusto           = "PL2016"
               tt_integr_apb_aprop_ctbl_pend.tta_cod_tip_fluxo_financ       = '2.01.05.01'
               tt_integr_apb_aprop_ctbl_pend.tta_val_aprop_ctbl             = dc-valor-total-titulo
               tt_integr_apb_aprop_ctbl_pend.tta_cod_pais                   = "BRA"         
               tt_integr_apb_aprop_ctbl_pend.tta_cod_unid_federac           = contrat.en-uf.
               
        message substitute ("ds-plano-contas-ems5: &1", ds-plano-contas-ems5) skip
                substitute ("estunemp.cd-unidade-negocio: &1", estunemp.cd-unidade-negocio) skip
                substitute ("contrat.char-16: &1", contrat.char-16) skip 
                substitute ("dc-valor-total-titulo: &1", dc-valor-total-titulo) skip.
/*         */
/*    end. */
    
    release tt_integr_apb_lote_impl.
    release tt_integr_apb_item_lote_impl.
    release tt_integr_apb_item_lote_impl_3.
    release tt_integr_apb_aprop_ctbl_pend.
    release tt_integr_apb_impto_impl_pend.    
    
    run prgfin/apb/apb900zf.py (input 4,
                                input "",
                                input-output table tt_integr_apb_item_lote_impl_3) no-error.        
    if  error-status:error
    then do:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Erro TECNICO na implantacao do titulo no contas a PAGAR: " + 
                                                              error-status:get-message(1).
        return no.               
    end.        
    
    for first tt_log_erros_atualiz:
        assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
               tmp-cpc-api-usuario-saida.lg-continua        = no
               tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Erro na implantacao do titulo no contas a PAGAR: " + 
                                                              tt_log_erros_atualiz.ttv_des_msg_erro + "|" +
                                                              tt_log_erros_atualiz.ttv_des_msg_ajuda.
        return no.               
    end.    
                           
end function.

function RegistraEstrutura returns logical 
    (in-modalidade          as   integer  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    

    create temp-estruturas-participantes.
    assign temp-estruturas-participantes.in-modalidade  = in-modalidade.
        
end function.

/**
 * ===============================================================================================================
 ************************ BLOCO PRINCIPAL
 * =============================================================================================================== 
 */
 
 define input  parameter table for tmp-cpc-api-usuario-entrada.
 define input  parameter table for tmp-usuario.
 define output parameter table for tmp-cpc-api-usuario-saida.
 
create tmp-cpc-api-usuario-saida.
assign tmp-cpc-api-usuario-saida.lg-undo-retry  = no
       tmp-cpc-api-usuario-saida.lg-continua    = yes.

find first tmp-cpc-api-usuario-entrada no-error.

if not available tmp-cpc-api-usuario-entrada
then do:
    assign tmp-cpc-api-usuario-saida.lg-undo-retry      = yes
           tmp-cpc-api-usuario-saida.ds-mensagem-erro   = "Temp de entrada nao informada".
    return.                   
end.    

if tmp-cpc-api-usuario-entrada.nm-ponto-chamada = "EXCLUI-FATURADO"
then do:
    RegistraEstrutura(05).    
    RegistraEstrutura(10).
    RegistraEstrutura(15).
    RegistraEstrutura(20).
    RegistraEstrutura(21).
    RegistraEstrutura(22).
    RegistraEstrutura(23).
    RegistraEstrutura(30).
    RegistraEstrutura(19).
    RegistraEstrutura(31).
    RegistraEstrutura(45).
    RegistraEstrutura(55).
    RegistraEstrutura(70).
    RegistraEstrutura(47).
        
    if not EstruturasParticipantes()
    then leave.
        
    ExcluirBeneficiarioFaturamentoPosterior().
end.
