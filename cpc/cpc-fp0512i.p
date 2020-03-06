/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i CPCFONTES/CPC-FP0512I.P 1.02.00.006}  /*** 010006 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
{include/i-license-manager.i cpc-fp0512i MCP}
&ENDIF

/*******************************************************************************
       Programa .....: cpc-fp0512i.p                                         
       Data .........: 04 de Dezembro de 2007                                  
       Sistema ......: FP - Faturamento
       Empresa ......: DATASUL Saude                                           
       Cliente ......: UNIMED Porto Alegre                                     
       Programador ..: Rudah Billig                                            
       Objetivo .....: Logica da CPC usada no programa fp0512i
*******************************************************************************/


/* ---------------------------------- Definicoes das Tabelas Temporarias --- */
{cpc/cpc-fp0512i.i} 

/* -------- DECLARACAO DE VARIAVEIS COMPARTILHADAS COM PROGS. CHAMADORES --- */
{fpp/fp0711a.i4}
 
def temp-table wk-evento-imposto no-undo
    field cd-evento     like fatueven.cd-evento
    field cd-imposto    like dzimposto.cd-imposto
    field vl-base       as dec
    field pc-aliquota   like evenimp.pc-aliquota
    index cd-evento
          cd-imposto.
def var nr-rowid-usuario-aux    as rowid                               no-undo.
def var nr-rowid-proposta-aux    as rowid                               no-undo.

def buffer buf-propost for propost.
def buffer buf-usuario for usuario.
def buffer bufer-usuario for usuario.
def buffer bufer-propost for propost.

/* ------------------------------------------------ Variaveis Auxiliares --- */
def var c-versao                as char                                no-undo.
def var dt-ult-fat-aux          as date                                no-undo.
def var lg-achei-estrutura-aux  as log                                 no-undo.

function VerificaSaldoNota returns logical 
    (  ) forward.

/*=================================================================================*/
                  
def shared temp-table       w-fateve         no-undo   like fatueven.
/* --- Definicao das temp's w-fatsemreaj e w-vlbenef ----------------------- */
{fpp/fp0711a.i11 "shared"} 

assign c-versao = c_prg_vrs.
{hdp/hdlog.i}  /* - Include necessario para logs do Sistema, nao retirar --- */

/* ------------------------ Definicoes dos Parametros de Entrada e Saida --- */
def input  parameter table for tmp-cpc-fp0512i-entrada.
def input-output  parameter table for wk-evento-imposto.
def output parameter table for tmp-cpc-fp0512i-saida.

find first tmp-cpc-fp0512i-entrada no-lock no-error.

if avail tmp-cpc-fp0512i-entrada 
then do:
       case tmp-cpc-fp0512i-entrada.nm-ponto-chamada:
           when "VER-USUARIO" 
           then do:              
                  find usuario where rowid(usuario) = tmp-cpc-fp0512i-entrada.nr-rowid-usuario exclusive-lock no-error.

                  if avail usuario 
                  then do:
                  
                         if   usuario.cd-sit-usuario >= 5
                          and usuario.cd-sit-usuario <= 7
                          and usuario.dt-data-reativa <> ?
                         then do:
 
                                find ter-ade where ter-ade.cd-modalidade = usuario.cd-modalidade
                                               and ter-ade.nr-ter-adesao = usuario.nr-ter-adesao
                                                   no-lock no-error.
                                if   not avail ter-ade
                                then do:
                                       create tmp-cpc-fp0512i-saida.
                                       assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                                              tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Termo de Adesao nao cadastrado.".
                                       return.
                                     end.
        
        
                                if    int(usuario.aa-ult-fat) <> 0 
                                  and int(usuario.mm-ult-fat) <> 0
                                  and (ter-ade.aa-ult-fat <> usuario.aa-ult-fat
                                    or ter-ade.mm-ult-fat <> usuario.mm-ult-fat)
        
                                  /*and usuario.u-date-1 = ?*/
                                then assign usuario.u-date-1 = date(usuario.mm-ult-fat,01,usuario.aa-ult-fat).

                         end.
                       end.

                  else do:
                         create tmp-cpc-fp0512i-saida.
                         assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                                tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Usuario nao encontrado.".
                       end.
                end.
                
                       /* ----- ponto considerado no programa fp0512i.i ----- */
     when "CRIA-EVEN-PROG" /* cpc para alterar a data de exclusao do beneficiario */
     then do:
             create tmp-cpc-fp0512i-saida.
             assign tmp-cpc-fp0512i-saida.vl-total-nota = tmp-cpc-fp0512i-entrada.vl-total-nota.  

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
             THEN VerificaSaldoNota().              
             ELSE RETURN.
                          
             /* ler todos os benefs do termo que tem devolucao RN412*/             
             for each event-progdo-bnfciar where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
                                             and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
                                             and event-progdo-bnfciar.aa-referencia = aa-ref-aux
                                             and event-progdo-bnfciar.mm-referencia = mm-ref-aux
                                             and (event-progdo-bnfciar.cd-evento    = 621 /*Evento da RN 412*/
                                                  or event-progdo-bnfciar.cd-evento = 622
                                                  or event-progdo-bnfciar.cd-evento = 623
                                                  or event-progdo-bnfciar.cd-evento = 624)
                                             and event-progdo-bnfciar.nr-sequencia  = 0 exclusive-lock: /* nr-sequencia = 0 indica que ainda nao foi faturado */
                                             
                 assign cd-evento-aux = event-progdo-bnfciar.cd-evento  
                        vl-evento-aux = event-progdo-bnfciar.vl-evento.   
                        
                                             
                 run calculo-programado-valor. /* Calcula e grava nas tabelas do sistema os valores*/    
                                             
             end.                                
              
          end. 
     
        end case.
     end.
  
/* ------------------------------ ROTINA PARA EVENTOS PROGRAMADOS (VALOR) --- */
procedure calculo-programado-valor:
  def var nr-idade-usuario            as int                              no-undo.
  def var lg-erro-aux                 as log                              no-undo.
  def var nr-faixa-usu-prog-aux       like teadgrpa.nr-faixa-etaria       no-undo.
  def var cd-contrat-aux              like vlbenef.cd-contratante         no-undo.    
  def var cd-contrat-origem-aux       like vlbenef.cd-contratante-origem  no-undo.
  def var tot-vl-prog-aux             like fatueven.vl-evento             no-undo.
  def var vl-total-benef-aux          like fatueven.vl-evento             no-undo.
  
find first usuario where usuario.cd-modalidade = cd-modalidade-aux
                     and usuario.nr-ter-adesao = nr-ter-ade-aux
                     and usuario.cd-usuario    = event-progdo-bnfciar.cd-usuario no-lock no-error.
                          
 if not avail usuario 
 then do:
         assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Usuario nao Cadastrado".
            
         return.  
    end. 

 find first propost where propost.cd-modalidade = cd-modalidade-aux
                      and propost.nr-ter-adesao = nr-ter-ade-aux no-lock no-error.
                           
 if not avail propost
 then do:
         assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Proposta nao Cadastrada".
            
         return.  
    end.      

 find first ter-ade where ter-ade.cd-modalidade = cd-modalidade-aux
                      and ter-ade.nr-ter-adesao = nr-ter-ade-aux
                          no-lock no-error.
 if not avail ter-ade 
 then do:
         assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Termo de Adesao nao Cadastrado".
            
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
       assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
              tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Erro no calculo da Idade do Beneficiario".
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
 

find first vlbenef where vlbenef.cd-modalidade         = cd-modalidade-aux                 
                     and vlbenef.cd-contratante        = cd-contrat-aux                
                     and vlbenef.cd-contratante-origem = cd-contrat-origem-aux        
                     and vlbenef.nr-ter-adesao         = nr-ter-ade-aux             
                     and vlbenef.aa-referencia         = aa-ref-aux                        
                     and vlbenef.mm-referencia         = mm-ref-aux                        
                     and vlbenef.cd-evento             = cd-evento-aux /*VER PRA PEGAR DA TIPELEVEN*/
                     and vlbenef.cd-usuario            = usuario.cd-usuario no-lock no-error.
                     
if not avail vlbenef
then do:     
     
       /* create w-vlbenef.
       assign w-vlbenef.cd-modalidade           = cd-modalidade-aux           
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
                w-vlbenef.vl-usuario            = vl-evento-aux
                w-vlbenef.pc-proporcional       = 1. */ 
               
       
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
              vlbenef.char-1                = event-progdo-bnfciar.cod-livre-1.
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
          assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                 tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Tipo Plano x Evento nao Cadastrado".
            
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
                           input  year(tmp-cpc-fp0512i-entrada.dt-emissao-aux),
                           input  month(tmp-cpc-fp0512i-entrada.dt-emissao-aux),
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
           assign tmp-cpc-fp0512i-saida.lg-undo-retry    = yes
                  tmp-cpc-fp0512i-saida.ds-mensagem-erro = "Conta Contabil nao Cadastrada".
            
           return.  
      end.                        


find first fatueven where fatueven.cd-modalidade   = cd-modalidade-aux
                      and fatueven.nr-ter-adesao   = nr-ter-ade-aux
                      and fatueven.aa-referencia   = aa-ref-aux
                      and fatueven.mm-referencia   = mm-ref-aux
                      and fatueven.nr-sequencia    = nr-sequencia-aux
                      and fatueven.cd-evento       = cd-evento-aux
                              exclusive-lock no-error.
if not avail fatueven
then do:   
       create fatueven.
       assign fatueven.cd-modalidade   = cd-modalidade-aux
              fatueven.nr-ter-adesao   = nr-ter-ade-aux
              fatueven.aa-referencia   = aa-ref-aux
              fatueven.mm-referencia   = mm-ref-aux
              fatueven.nr-sequencia    = nr-sequencia-aux
              fatueven.cd-evento       = cd-evento-aux
              fatueven.ct-codigo       = ct-codigo-aux
              fatueven.sc-codigo       = sc-codigo-aux
              fatueven.qt-evento       = event-progdo-bnfciar.qt-evento
              fatueven.vl-evento       = vl-evento-aux
              fatueven.lg-cred-deb     = no
              fatueven.lg-destacado    = lg-destacado-aux
              fatueven.lg-modulo       = lg-modulo-aux
              fatueven.cd-userid       = v_cod_usuar_corren
              fatueven.dt-atualizacao  = today.      

       case ter-ade.in-contratante-mensalidade:
            when 1
            then assign fatueven.cd-contratante        = cd-contrat-aux
                        fatueven.cd-contratante-origem = cd-contrat-origem-aux.
            when 0
            then assign fatueven.cd-contratante        = cd-contrat-aux
                        fatueven.cd-contratante-origem = cd-contrat-origem-aux.
       end case.
    end.   
else assign fatueven.vl-evento = fatueven.vl-evento + vl-evento-aux
            fatueven.qt-evento = fatueven.qt-evento + 1. 
              

assign tmp-cpc-fp0512i-saida.vl-total-nota        = tmp-cpc-fp0512i-saida.vl-total-nota - vl-evento-aux
       event-progdo-bnfciar.nr-sequencia          = nr-sequencia-aux  /*Cobrado*/
       event-progdo-bnfciar.cd-contratante        = cd-contrat-aux       
       event-progdo-bnfciar.cd-contratante-origem = cd-contrat-origem-aux.

end procedure.

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
    define variable dc-saldo-proximo-mes        as   decimal        no-undo.
    define variable dc-valor-parcela            as   decimal        no-undo.
    
    define BUFFER b-event-progdo-bnfciar for event-progdo-bnfciar.
    
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
    
    assign dc-valor-total-nota = tmp-cpc-fp0512i-entrada.vl-total-nota
           dc-valor-total-nota = dc-valor-total-nota - parafatu.vl-fat-min
           dc-saldo-total      = dc-valor-total-nota - dc-total-eventos
           dc-multiplicador    = dc-valor-total-nota / dc-total-eventos.
    
    message substitute ("total nota: &1", tmp-cpc-fp0512i-entrada.vl-total-nota) skip
            substitute ("total evento: &1", dc-total-eventos) skip
            substitute ("total saldo: &1", dc-saldo-total) skip
            substitute ("valor min fat: &1", parafatu.vl-fat-min).
             
    if dc-total-eventos > dc-valor-total-nota 
    then do:
        /** Altera o valor de cada registro para o valor calculado da proporcional */
        for each event-progdo-bnfciar EXCLUSIVE-LOCK
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
 
            assign in-proximo-ano = event-progdo-bnfciar.aa-referencia
                   in-proximo-mes = event-progdo-bnfciar.mm-referencia + 1.

            if in-proximo-mes = 13
            then do:
                   assign in-proximo-ano = in-proximo-ano + 1
                          in-proximo-mes = 1.
            end.
           
            assign dc-valor-parcela               = event-progdo-bnfciar.vl-evento
                   event-progdo-bnfciar.vl-evento = dc-valor-parcela * dc-multiplicador
                   dc-saldo-proximo-mes           = dc-valor-parcela - event-progdo-bnfciar.vl-evento.
                   
            create b-event-progdo-bnfciar.
            buffer-copy event-progdo-bnfciar
                 except event-progdo-bnfciar.aa-referencia
                        event-progdo-bnfciar.mm-referencia
                     to b-event-progdo-bnfciar.                   

            assign b-event-progdo-bnfciar.mm-referencia = in-proximo-mes
                   b-event-progdo-bnfciar.aa-referencia = in-proximo-ano
                   b-event-progdo-bnfciar.vl-evento     = dc-saldo-proximo-mes.                   
        end.                                    
    end.        
end function.     
     
     
     
     
     
     
     
     




