
{include/i-prgvrs.i cpc/cpc-fp0512j.p 1.02.00.111}  /*** 010009 ***/
/******************************************************************************
    Programa .....: cpc-fp0512j.p
    Data .........: 22/05/2017
    Sistema ......:
    Empresa ......: DATASUL SAUDE
    Cliente ......: UNIMED Fesp
    Programador ..: Rodrigo Bueno
    Objetivo .....: Cpc com logica especifica do cliente
******************************************************************************/

/* ----------------------- DEFINICAO DAS TEMPORARIAS ----------------------- */
{cpc/cpc-fp0512j.i}  

/* -------- DECLARACAO DE VARIAVEIS COMPARTILHADAS COM PROGS. CHAMADORES --- */
{fpp/fp0711a.i4}


/* ------------------------------------------------ Variaveis Auxiliares --- */
def var c-versao                as char                                no-undo.

function VerificaSaldoNota returns logical 
    (  ) forward.



def temp-table wk-evento-imposto no-undo
    field cd-evento     like fatueven.cd-evento
    field cd-imposto    like dzimposto.cd-imposto
    field vl-base       as dec
    field pc-aliquota   like evenimp.pc-aliquota
    index cd-evento
          cd-imposto.
          
define temp-table temp-evento-proximo-periodo   no-undo
    field in-usuario                            as   integer.       

DEF TEMP-TABLE temp-event-programado NO-UNDO LIKE event-progdo-bnfciar.
             
/*=================================================================================*/
def shared temp-table w-fateve    no-undo  like fatueven.
def shared temp-table w-fatgrau   no-undo  like fatgrmod.

/* ----------------------- TEMP-TABLE UTILIZADA PELOS VALORES POR BENEF. --- */
{fpp/fp0711a.i11 "shared"}


/*---------------------------------------------------------------------------*/
assign  c-versao = "7.00.000".

/*{hdp/hdlog.i}   - Include necessario para log?s do Sistema --- */
def new global shared var v_cod_usuar_corren as character
                          format "x(12)":U label "Usuÿrio Corrente"
                                        column-label "Usuÿrio Corrente"  no-undo.       
def new global shared var in-origem-chamada-menu as character format "x(12)"    
                                                                         no-undo.

DEF VAR lg-valor-posterior   AS LOG INITIAL NO                           NO-UNDO.
DEF VAR cd-usuario-event-aux LIKE usuario.cd-usuario                     NO-UNDO.
DEF VAR qt-evento-aux        LIKE event-progdo-bnfciar.qt-evento         NO-UNDO.
/* ----------------------------- testa se Serious 7.0 ou GESTAO DE PLANOS ---*/
/* ------------- CASO FOR GESTÇO DE PLANOS RETORNA A VERSÇO DO ROUNTABLE --- */
if in-origem-chamada-menu <> "TEMENU70"
then assign c-versao      = /*c_prg_vrs.*/  "7.01.000".

if session:multitasking-interval = 1
then run rtp/rthdlog.p (input c-versao,
                        input program-name(1)).

/* -------------------------------------------------- INICIO DO PROCESSO --- */
def input  parameter table for tmp-cpc-fp0512j-entrada.
def input-output  parameter table for wk-evento-imposto.
def output parameter table for tmp-cpc-fp0512j-saida.

find first tmp-cpc-fp0512j-entrada no-lock no-error.

empty temp-table temp-evento-proximo-periodo.

if   not avail tmp-cpc-fp0512j-entrada
then return.

/* ------------------------------------------------------------ WAL-MART --- */
if   tmp-cpc-fp0512j-entrada.nm-ponto-chamada = "CRIA-EVEN-PROG"
then do:
    create tmp-cpc-fp0512j-saida.                  
    assign tmp-cpc-fp0512j-saida.vl-total-nota = tmp-cpc-fp0512j-entrada.vl-total-nota.
    
    if can-find (first event-progdo-bnfciar 
                 where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
                   and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
                   and event-progdo-bnfciar.aa-referencia = aa-ref-aux
                   and event-progdo-bnfciar.mm-referencia = mm-ref-aux
                   and (   event-progdo-bnfciar.cd-evento = 621 /*Evento da RN 412*/
                        or event-progdo-bnfciar.cd-evento = 622
                        or event-progdo-bnfciar.cd-evento = 623
                        or event-progdo-bnfciar.cd-evento = 624)
                   and event-progdo-bnfciar.nr-sequencia  = 0)
    then do:
        VerificaSaldoNota().              
    end.                    

    IF lg-valor-posterior 
    THEN DO:
           /* Le a partir da temp-table visto que houve altera‡Æo nos valores originais*/
           for each temp-event-programado where temp-event-programado.cd-modalidade = cd-modalidade-aux                          
                                            and temp-event-programado.nr-ter-adesao = nr-ter-ade-aux
                                            and temp-event-programado.aa-referencia = aa-ref-aux
                                            and temp-event-programado.mm-referencia = mm-ref-aux
                                            and (   temp-event-programado.cd-evento = 621 /*Evento da RN 412*/
                                                 or temp-event-programado.cd-evento = 622
                                                 or temp-event-programado.cd-evento = 623
                                                 or temp-event-programado.cd-evento = 624)
                                            and temp-event-programado.nr-sequencia  = 0 no-lock: /* nr-sequencia = 0 indica que ainda nao foi faturado */
                                           
               assign cd-evento-aux        = temp-event-programado.cd-evento  
                      vl-evento-aux        = temp-event-programado.vl-evento
                      cd-usuario-event-aux = temp-event-programado.cd-usuario
                      qt-evento-aux        = temp-event-programado.qt-evento.  
                      
                                           
               run calculo-programado-valor. /* Calcula e grava nas tabelas do sistema os valores*/    
                                           
           end.
         END.
    ELSE DO:
           /* ler todos os benefs do termo que tem devolucao RN412*/
           for each event-progdo-bnfciar where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
                                           and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
                                           and event-progdo-bnfciar.aa-referencia = aa-ref-aux
                                           and event-progdo-bnfciar.mm-referencia = mm-ref-aux
                                           and (   event-progdo-bnfciar.cd-evento = 621 /*Evento da RN 412*/
                                                or event-progdo-bnfciar.cd-evento = 622
                                                or event-progdo-bnfciar.cd-evento = 623
                                                or event-progdo-bnfciar.cd-evento = 624)
                                           and event-progdo-bnfciar.nr-sequencia  = 0 no-lock: /* nr-sequencia = 0 indica que ainda nao foi faturado */
                                           
               assign cd-evento-aux        = event-progdo-bnfciar.cd-evento  
                      vl-evento-aux        = event-progdo-bnfciar.vl-evento   
                      cd-usuario-event-aux = event-progdo-bnfciar.cd-usuario
                      qt-evento-aux        = event-progdo-bnfciar.qt-evento.
                                                           
               run calculo-programado-valor. /* Calcula e grava nas tabelas do sistema os valores*/    
                                           
           end.
         END.                                           
end.
     
/* ------------------------------ ROTINA PARA EVENTOS PROGRAMADOS (VALOR) --- */


/* ************************  Function Prototypes ********************** */


procedure calculo-programado-valor:
  def var nr-idade-usuario            as int                              no-undo.
  def var lg-erro-aux                 as log                              no-undo.
  def var nr-faixa-usu-prog-aux       like teadgrpa.nr-faixa-etaria       no-undo.
  def var cd-contrat-aux              like vlbenef.cd-contratante         no-undo.    
  def var cd-contrat-origem-aux       like vlbenef.cd-contratante-origem  no-undo.
  def var tot-vl-prog-aux             like w-fateve.vl-evento             no-undo.
  def var vl-total-benef-aux          like w-fateve.vl-evento             no-undo.
  
find first usuario where usuario.cd-modalidade = cd-modalidade-aux
                     and usuario.nr-ter-adesao = nr-ter-ade-aux
                     and usuario.cd-usuario    = cd-usuario-event-aux no-lock no-error.
                          
 if not avail usuario 
 then do:
         assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Usuario nao Cadastrado".
            
         return.  
    end. 

 find first propost where propost.cd-modalidade = cd-modalidade-aux
                      and propost.nr-ter-adesao = nr-ter-ade-aux no-lock no-error.
                           
 if not avail propost
 then do:
         assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Proposta nao Cadastrada".
            
         return.  
    end.      

 find first ter-ade where ter-ade.cd-modalidade = cd-modalidade-aux
                      and ter-ade.nr-ter-adesao = nr-ter-ade-aux
                          no-lock no-error.
 if not avail ter-ade 
 then do:
         assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Termo de Adesao nao Cadastrado".
            
         return.  
     end.
      
 case ter-ade.in-contratante-mensalidade:
   when 1 
   then do:
           find first contrat 
                where contrat.nr-insc-contratante = propost.nr-insc-contrat-origem 
                      no-lock no-error.
           if available contrat
           then assign cd-contrat-aux        = contrat.cd-contratante
                       cd-contrat-origem-aux = propost.nr-insc-contratante.
        end.
                                
   when 0 
   then assign cd-contrat-aux        = propost.cd-contratante
               cd-contrat-origem-aux = propost.nr-insc-contrat-origem.
 end case.
 
  
run rtp/rtidade.p (input  usuario.dt-nascimento,    
                   input  today,
                   output nr-idade-usuario,
                   output lg-erro-aux).
if lg-erro-aux
then do:
       assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
              tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Erro no calculo da Idade do Beneficiario".
       return.
    end.    
 
 
if propost.lg-faixa-etaria-esp
then do:
        for each teadgrpa where teadgrpa.cd-modalidade      = propost.cd-modalidade     
                            and teadgrpa.nr-proposta        = propost.nr-proposta       
                            and teadgrpa.cd-grau-parentesco = usuario.cd-grau-parentesco
                                no-lock.
                         
            if  teadgrpa.nr-idade-minima <= nr-idade-usuario 
            and teadgrpa.nr-idade-maxima >= nr-idade-usuario
            then assign nr-faixa-usu-prog-aux = teadgrpa.nr-faixa-etaria.
        end.                                 
     end.
 else do:
         for each pl-gr-pa  use-index pl-gr-pa1
            where pl-gr-pa.cd-modalidade      = propost.cd-modalidade     
              and pl-gr-pa.cd-plano           = propost.cd-plano          
              and pl-gr-pa.cd-tipo-plano      = propost.cd-tipo-plano     
              and pl-gr-pa.cd-grau-parentesco = usuario.cd-grau-parentesco
                  no-lock.
                               
             if  pl-gr-pa.nr-idade-minima <= nr-idade-usuario 
             and pl-gr-pa.nr-idade-maxima >= nr-idade-usuario
             then assign nr-faixa-usu-prog-aux = pl-gr-pa.nr-faixa-etaria.
         end.
       end. 
 

find first w-vlbenef where w-vlbenef.cd-modalidade       = cd-modalidade-aux                 
                     and w-vlbenef.cd-contratante        = cd-contrat-aux                
                     and w-vlbenef.cd-contratante-origem = cd-contrat-origem-aux        
                     and w-vlbenef.nr-ter-adesao         = nr-ter-ade-aux             
                     and w-vlbenef.aa-referencia         = aa-ref-aux                        
                     and w-vlbenef.mm-referencia         = mm-ref-aux                        
                     and w-vlbenef.cd-evento             = cd-evento-aux /*VER PRA PEGAR DA TIPELEVEN*/
                     and w-vlbenef.cd-usuario            = usuario.cd-usuario no-lock no-error.
                     
if not avail w-vlbenef
then do:     
       create   w-vlbenef.
       assign   w-vlbenef.cd-modalidade         = cd-modalidade-aux           
                w-vlbenef.cd-contratante        = cd-contrat-aux
                w-vlbenef.cd-contratante-origem = cd-contrat-origem-aux
                w-vlbenef.nr-ter-adesao         = nr-ter-ade-aux        
                w-vlbenef.aa-referencia         = aa-ref-aux                     
                w-vlbenef.mm-referencia         = mm-ref-aux                     
                w-vlbenef.nr-sequencia          = nr-sequencia-aux 
                w-vlbenef.cd-padrao-cobertura   = usuario.cd-padrao-cobertura   
                w-vlbenef.qt-fator-mult         = 1
                w-vlbenef.qt-fator-tr-faixa     = 1  
                w-vlbenef.qt-fator-contippl     = 1
                w-vlbenef.qt-fator-forpagtx     = 1
                w-vlbenef.cd-usuario            = usuario.cd-usuario
                w-vlbenef.nr-faixa-etaria       = nr-faixa-usu-prog-aux
                w-vlbenef.cd-grau-parentesco    = usuario.cd-grau-parentesco
                w-vlbenef.cd-evento             = cd-evento-aux
                w-vlbenef.cd-modulo             = 0
                w-vlbenef.vl-usuario            = vl-evento-aux * -1
                w-vlbenef.vl-total              = vl-evento-aux * -1
                w-vlbenef.pc-proporcional       = 1. 
       /*                        
       
       /*----cria vlbenef-----*/      
       create vlbenef.
       assign vlbenef.cd-modalidade         = cd-modalidade-aux           
              vlbenef.cd-contratante        = cd-contrat-aux
              vlbenef.cd-contratante-origem = cd-contrat-origem-aux
              vlbenef.nr-ter-adesao         = nr-ter-ade-aux        
              vlbenef.aa-referencia         = aa-ref-aux                     
              vlbenef.mm-referencia         = mm-ref-aux                     
              vlbenef.nr-sequencia          = nr-sequencia-aux               
              vlbenef.cd-usuario            = usuario.cd-usuario            
              vlbenef.cd-evento             = cd-evento-aux                
              vlbenef.cd-modulo             = 0         
              vlbenef.nr-faixa-etaria       = nr-faixa-usu-prog-aux
              vlbenef.cd-grau-parentesco    = usuario.cd-grau-parentesco
              vlbenef.vl-usuario            = vl-evento-aux   
              vlbenef.vl-total              = vl-evento-aux 
              vlbenef.cd-userid             = v_cod_usuar_corren          
              vlbenef.dt-atualizacao        = today
              vlbenef.char-1                = event-progdo-bnfciar.cod-livre-1. */
   end.
       
  /* /*------- atualiza tot-----------*/
   assign vl-total-benef-aux = 0.
   
   for each  vlbenef fields( vlbenef.cd-evento
                             vlbenef.vl-usuario ) 
        where vlbenef.cd-modalidade = cd-modalidade-aux
          and vlbenef.nr-ter-adesao = nr-ter-ade-aux
          and vlbenef.aa-referencia = aa-ref-aux
          and vlbenef.mm-referencia = mm-ref-aux
          and vlbenef.cd-usuario    = event-progdo-bnfciar.cd-usuario
              exclusive-lock:
                                       
         find evenfatu 
         where evenfatu.in-entidade = "FT"
           and evenfatu.cd-evento   = vlbenef.cd-evento
               no-lock no-error.
         if avail evenfatu
         then do:
                if evenfatu.lg-cred-deb
                then assign vl-total-benef-aux = vl-total-benef-aux + vlbenef.vl-usuario.
                else assign vl-total-benef-aux = vl-total-benef-aux - vlbenef.vl-usuario.
              end.
   end.
                                   
   find first vlbenef where vlbenef.cd-modalidade         = cd-modalidade-aux
                        and vlbenef.nr-ter-adesao         = nr-ter-ade-aux
                        and vlbenef.aa-referencia         = aa-ref-aux
                        and vlbenef.mm-referencia         = mm-ref-aux
                        and vlbenef.nr-sequencia          = nr-sequencia-aux
                        and vlbenef.cd-usuario            = event-progdo-bnfciar.cd-usuario
                            exclusive-lock no-error.
   if avail vlbenef 
   then assign vlbenef.vl-total = vl-total-benef-aux. */
   
   

  /* -----Busca conta evento 4---------------------*/
  find first  tipleven
         where tipleven.in-entidade    = "FT"
           and tipleven.cd-modalidade  = propost.cd-modalidade
           and tipleven.cd-plano       = propost.cd-plano
           and tipleven.cd-tipo-plano  = propost.cd-tipo-plano
           and tipleven.cd-forma-pagto = propost.cd-forma-pagto             
           and tipleven.cd-evento      = cd-evento-aux
           and tipleven.lg-ativo       = yes
           no-lock no-error.
   if not avail tipleven
   then do:
          assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
                 tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Tipo Plano x Evento nao Cadastrado".
            
          return.  
      end.      
  /* ------------------------------------------ Conta Contabil --- */
  run rtp/rtct-contabeis.p(input  tipleven.cd-modalidade,
                           input  tipleven.cd-plano,
                           input  tipleven.cd-tipo-plano,
                           input  tipleven.cd-forma-pagto,
                           input  tipleven.in-entidade,
                           input  tipleven.cd-evento,
                           input  tipleven.cd-modulo,
                           input  year(tmp-cpc-fp0512j-entrada.dt-emissao-aux),
                           input  month(tmp-cpc-fp0512j-entrada.dt-emissao-aux),
                           input  0,
                           input  "",
                           input  ?,
                           input  propost.in-tipo-contratacao,
                           input 1,
                           output lg-ct-contabil-aux,
                           output ct-codigo-aux,
                           output sc-codigo-aux,
                           output ct-codigo-dif-aux,
                           output sc-codigo-dif-aux,
                           output ct-codigo-dif-neg-aux,
                           output sc-codigo-dif-neg-aux,
                           output lg-evencontde-aux) no-error.
   if error-status:error
   then do:
           assign tmp-cpc-fp0512j-saida.lg-undo-retry    = yes
                  tmp-cpc-fp0512j-saida.ds-mensagem-erro = "Conta Contabil nao Cadastrada".
            
           return.  
      end.                        


find first w-fateve where w-fateve.cd-modalidade   = cd-modalidade-aux
                      and w-fateve.nr-ter-adesao   = nr-ter-ade-aux
                      and w-fateve.aa-referencia   = aa-ref-aux
                      and w-fateve.mm-referencia   = mm-ref-aux
                      and w-fateve.nr-sequencia    = nr-sequencia-aux
                      and w-fateve.cd-evento       = cd-evento-aux
                              no-lock no-error.
if not avail w-fateve
then do:   
       create w-fateve.
       assign w-fateve.cd-modalidade   = cd-modalidade-aux
              w-fateve.nr-ter-adesao   = nr-ter-ade-aux
              w-fateve.aa-referencia   = aa-ref-aux
              w-fateve.mm-referencia   = mm-ref-aux
              w-fateve.nr-sequencia    = nr-sequencia-aux
              w-fateve.cd-evento       = cd-evento-aux
              w-fateve.ct-codigo       = ct-codigo-aux
              w-fateve.sc-codigo       = sc-codigo-aux
              w-fateve.qt-evento       = qt-evento-aux
              w-fateve.vl-evento       = vl-evento-aux
              w-fateve.lg-cred-deb     = no
              w-fateve.lg-destacado    = lg-destacado-aux
              w-fateve.lg-modulo       = lg-modulo-aux
              w-fateve.cd-userid       = v_cod_usuar_corren
              w-fateve.dt-atualizacao  = today.      

       case ter-ade.in-contratante-mensalidade:
            when 1
            then assign w-fateve.cd-contratante        = cd-contrat-aux
                        w-fateve.cd-contratante-origem = cd-contrat-origem-aux.
            when 0
            then assign w-fateve.cd-contratante        = cd-contrat-aux
                        w-fateve.cd-contratante-origem = cd-contrat-origem-aux.
       end case.
    end.  
 else assign w-fateve.vl-evento = w-fateve.vl-evento + vl-evento-aux
             w-fateve.qt-evento = w-fateve.qt-evento + 1.   

assign tmp-cpc-fp0512j-saida.vl-total-nota = tmp-cpc-fp0512j-saida.vl-total-nota - vl-evento-aux.
    
end procedure.


/* ************************  Function Implementations ***************** */

function VerificaSaldoNota returns logical 
	(  ):
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/	
    define variable dc-total-eventos            as   decimal        no-undo.
    define variable dc-saldo-total              as   decimal        no-undo.
    define variable dc-valor-total-nota         as   decimal        no-undo.
    define variable dc-multiplicador            as   decimal        no-undo. 
    define variable in-proximo-ano              as   integer        no-undo.
    define variable in-proximo-mes              as   integer        no-undo.
    define variable dc-valor-parcela            as   decimal        no-undo.
    
    define buffer   buf-event-progdo-bnfciar    for  event-progdo-bnfciar.
    
    find first parafatu no-lock.
        
    for each event-progdo-bnfciar no-lock
       where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
         and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
         and event-progdo-bnfciar.aa-referencia = aa-ref-aux
         and event-progdo-bnfciar.mm-referencia = mm-ref-aux
         and (   event-progdo-bnfciar.cd-evento = 621 /*Evento da RN 412*/
              or event-progdo-bnfciar.cd-evento = 622
              or event-progdo-bnfciar.cd-evento = 623
              or event-progdo-bnfciar.cd-evento = 624)
         and event-progdo-bnfciar.nr-sequencia  = 0: /* nr-sequencia = 0 indica que ainda nao foi faturado */
        
        assign dc-total-eventos = dc-total-eventos + event-progdo-bnfciar.vl-evento.             
         
    end.       

    assign dc-valor-total-nota          = tmp-cpc-fp0512j-entrada.vl-total-nota
           dc-valor-total-nota          = dc-valor-total-nota - parafatu.vl-fat-min
           dc-saldo-total               = dc-valor-total-nota - dc-total-eventos
           dc-multiplicador             = dc-valor-total-nota / dc-total-eventos.
    
    message substitute ("total nota: &1", tmp-cpc-fp0512j-entrada.vl-total-nota) skip
            substitute ("total evento: &1", dc-total-eventos) skip
            substitute ("total saldo: &1", dc-saldo-total) skip
            substitute ("valor min fat: &1", parafatu.vl-fat-min).

    lg-valor-posterior = NO.
             
    if dc-total-eventos > dc-valor-total-nota         
    then do:
           lg-valor-posterior = YES. /* Houve valor posterior */
           /** Altera o valor de cada registro para o valor calculado da proporcional */
           for each event-progdo-bnfciar no-lock
              where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
                and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
                and event-progdo-bnfciar.aa-referencia = aa-ref-aux
                and event-progdo-bnfciar.mm-referencia = mm-ref-aux
                and (   event-progdo-bnfciar.cd-evento = 621
                     or event-progdo-bnfciar.cd-evento = 622 /*Evento da RN 412*/
                     or event-progdo-bnfciar.cd-evento = 623
                     or event-progdo-bnfciar.cd-evento = 624)
                and event-progdo-bnfciar.nr-sequencia  = 0 /* nr-sequencia = 0 indica que ainda nao foi faturado */ 
                    break by event-progdo-bnfciar.cd-usuario:

               CREATE temp-event-programado. /* Cria temp-table para mostrar os valores alterados na simula‡Æo */
               BUFFER-COPY event-progdo-bnfciar TO temp-event-programado.
               
               assign dc-valor-parcela                = event-progdo-bnfciar.vl-evento
                      temp-event-programado.vl-evento = dc-valor-parcela * dc-multiplicador.               
        end.                                    
    end.        
end function.     
     
