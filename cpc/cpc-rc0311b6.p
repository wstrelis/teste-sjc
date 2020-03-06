  
  

  message "aqui cpc-rc0311b6" view-as alert-box. 


  /* ---------------------------------- Definicao das variaveis auxiliares ------ */
  def var c-versao                 as char                              no-undo.
  def var ds-mens-aux              as char format "x(80)"               no-undo.

  def var lg-erro-aux              as log                               no-undo.
  def var lg-tonometria-aux        as log                               no-undo.
  def var lg-pacote-aux            as log                               no-undo.


  assign c-versao = "6.00.000".
  {include/i-prgvrs.i cpc/cpc-rc0311b6.p 2.00.00.000}
  {hdp/hdlog.i}  /*- Include necessaria para logs do Sistema nao retirar ------- */

  {cpc/cpc-rc0311b6.i}

  DEF input  PARAMETER table FOR tmp-cpc-rc0311b6-entrada.
  DEF output PARAMETER table FOR tmp-cpc-rc0311b6-saida.

  
  FIND FIRST tmp-cpc-rc0311b6-entrada NO-LOCK NO-ERROR.
  IF   tmp-cpc-rc0311b6-entrada.nm-ponto-chamada-cpc      = "VALIDA-GLOSA"
  THEN do:
       FOR EACH moviproc WHERE moviproc.cd-unidade = tmp-cpc-rc0311b6-entrada.cd-unidade-cpc      
                           AND moviproc.cd-unidade-prestadora = tmp-cpc-rc0311b6-entrada.cd-unidade-prestadora-cpc 
                           AND moviproc.cd-transacao          = tmp-cpc-rc0311b6-entrada.cd-transacao-cpc
                           AND moviproc.nr-serie-doc-original = tmp-cpc-rc0311b6-entrada.nr-serie-doc-original-cpc 
                           AND moviproc.nr-doc-original       = tmp-cpc-rc0311b6-entrada.nr-doc-original-cpc   
                           AND moviproc.nr-doc-sistema        = tmp-cpc-rc0311b6-entrada.nr-doc-sistema-cpc   
                           AND moviproc.nr-processo           = tmp-cpc-rc0311b6-entrada.nr-processo-cpc  
                           AND moviproc.nr-seq-digitacao      = tmp-cpc-rc0311b6-entrada.nr-seq-digitacao-cpc    
                                       NO-LOCK :

         IF   moviproc.cd-esp-amb        = 41 AND
              moviproc.cd-grupo-proc-amb = 30 AND
              moviproc.cd-procedimento   = 132 AND
              moviproc.dv-procedimento   = 3   AND
              moviproc.cd-pacote         = 0  /* AND
              MOVIPROC.CD-PRESTADOR      = ???? */
         THEN DO:   
              CREATE  tmp-cpc-rc0311b6-saida.
              ASSIGN  tmp-cpc-rc0311b6-saida.lg-erro      = YES
                      tmp-cpc-rc0311b6-saida.ds-mensagem  = "Pacote Obrigatorio para este prestador e procedimento"
                      tmp-cpc-rc0311b6-saida.lg-continua  = NO.                  

         END.
       END.
       
  END.

  FIND FIRST tmp-cpc-rc0311b6-saida NO-LOCK NO-ERROR .
  IF NOT AVAIL tmp-cpc-rc0311b6-saida
  THEN DO: 
       CREATE  tmp-cpc-rc0311b6-saida.
       ASSIGN  tmp-cpc-rc0311b6-saida.lg-erro      = NO
               tmp-cpc-rc0311b6-saida.ds-mensagem  = "" 
               tmp-cpc-rc0311b6-saida.lg-rtvalglo-cpc        = NO 
               tmp-cpc-rc0311b6-saida.cd-tipo-cob-cpc        = tmp-cpc-rc0311b6-entrada.cd-tipo-cob
               tmp-cpc-rc0311b6-saida.vl-uso-indevido-cpc    = tmp-cpc-rc0311b6-entrada.vl-uso-indevido
               tmp-cpc-rc0311b6-saida.cd-validacao-cpc       = tmp-cpc-rc0311b6-entrada.cd-validacao
               tmp-cpc-rc0311b6-saida.cd-forma-pagto-cob-cpc = tmp-cpc-rc0311b6-entrada.cd-forma-pagto-cob
               tmp-cpc-rc0311b6-saida.cd-tipo-pagamento-cpc  = tmp-cpc-rc0311b6-entrada.cd-tipo-pagamento.
  END.
                          .

  /* SE QUISER VALIDAR A GLOSA   PREENCHER OS CAMPOS ABAIXO.
  
   tmp-cpc-rc0311b6-saida.lg-rtvalglo-cpc
   tmp-cpc-rc0311b6-saida.cd-tipo-cob-cpc
   tmp-cpc-rc0311b6-saida.vl-uso-indevido-cpc
   tmp-cpc-rc0311b6-saida.cd-validacao-cpc
   tmp-cpc-rc0311b6-saida.cd-user-validacao-cpc
   tmp-cpc-rc0311b6-saida.cd-forma-pagto-cob-cpc
   tmp-cpc-rc0311b6-saida.cd-tipo-pagamento-cpc.
      */
