-- CREAZIONE TABELLA BASE UNIFICATA CON DATI CLIENTI, CONTI, TIPOLOGIE, E TRANSAZIONI
DROP TEMPORARY TABLE IF EXISTS db_clienti;

CREATE TEMPORARY TABLE db_clienti AS
SELECT
    cl.id_cliente,
    cl.nome,
    cl.cognome,
    cl.data_nascita,
    co.id_conto,
    co.id_tipo_conto,
    tc.desc_tipo_conto,
    t.data AS data_transazione,
    t.id_tipo_trans AS id_tipo_transazione,
    t.importo,
    tt.desc_tipo_trans,
    tt.segno
FROM cliente cl
LEFT JOIN conto co ON cl.id_cliente = co.id_cliente
LEFT JOIN tipo_conto tc ON co.id_tipo_conto = tc.id_tipo_conto
LEFT JOIN transazioni t ON co.id_conto = t.id_conto
LEFT JOIN tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione;

-- VISUALIZZAZIONE DI CONTROLLO
SELECT * FROM db_clienti LIMIT 100;

----------------------------------------------------------
-- CREAZIONE INDICATORI PER CLIENTE (TABELLE TEMPORANEE) --
----------------------------------------------------------

-- INDICATORE 1: ETÀ DEL CLIENTE
DROP TEMPORARY TABLE IF EXISTS eta_clienti;

CREATE TEMPORARY TABLE eta_clienti AS
SELECT
    id_cliente,
    YEAR(CURRENT_DATE()) - YEAR(MIN(data_nascita)) -
    (DATE_FORMAT(CURRENT_DATE(), '%m%d') < DATE_FORMAT(MIN(data_nascita), '%m%d')) AS eta
FROM db_clienti
GROUP BY id_cliente;

-- INDICATORE 2: NUMERO E SOMMA DELLE TRANSAZIONI IN USCITA
DROP TEMPORARY TABLE IF EXISTS transazioni_uscita;

CREATE TEMPORARY TABLE transazioni_uscita AS
SELECT
    id_cliente,
    COUNT(*) AS num_trans_uscita,
    SUM(importo) AS uscite_tot
FROM db_clienti
WHERE segno = '-'
GROUP BY id_cliente;

-- INDICATORE 3: NUMERO E SOMMA DELLE TRANSAZIONI IN ENTRATA
DROP TEMPORARY TABLE IF EXISTS transazioni_entrata;

CREATE TEMPORARY TABLE transazioni_entrata AS
SELECT
    id_cliente,
    COUNT(*) AS num_trans_entrata,
    SUM(importo) AS entrate_tot
FROM db_clienti
WHERE segno = '+'
GROUP BY id_cliente;

-- INDICATORE 4: NUMERO DI CONTI POSSEDUTI
DROP TEMPORARY TABLE IF EXISTS numero_conti;

CREATE TEMPORARY TABLE numero_conti AS
SELECT
    id_cliente,
    COUNT(id_conto) AS num_conti
FROM db_clienti
GROUP BY id_cliente;

-- INDICATORE 5: NUMERO DI CONTI PER TIPOLOGIA
DROP TEMPORARY TABLE IF EXISTS tipo_conti;

CREATE TEMPORARY TABLE tipo_conti AS
SELECT
    id_cliente,
    COUNT(CASE WHEN desc_tipo_conto = 'Conto Privati' THEN id_conto END) AS conto_privati,
    COUNT(CASE WHEN desc_tipo_conto = 'Conto Base' THEN id_conto END) AS conto_base,
    COUNT(CASE WHEN desc_tipo_conto = 'Conto Business' THEN id_conto END) AS conto_business,
    COUNT(CASE WHEN desc_tipo_conto = 'Conto Famiglie' THEN id_conto END) AS conto_famiglie
FROM db_clienti
GROUP BY id_cliente;

-- INDICATORE 6: TRANSAZIONI IN ENTRATA PER TIPOLOGIA DI CONTO E SOMMA IMPORTI
DROP TEMPORARY TABLE IF EXISTS transaz_positive_per_tipo_conto;

CREATE TEMPORARY TABLE transaz_positive_per_tipo_conto AS
SELECT
    id_cliente,
    COUNT(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Privati' THEN id_conto END) AS count_privati_in,
    COUNT(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Base' THEN id_conto END) AS count_base_in,
    COUNT(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Business' THEN id_conto END) AS count_business_in,
    COUNT(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Famiglie' THEN id_conto END) AS count_famiglie_in,
    
    SUM(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Privati' THEN importo ELSE 0 END) AS somma_privati_in,
    SUM(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Base' THEN importo ELSE 0 END) AS somma_base_in,
    SUM(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Business' THEN importo ELSE 0 END) AS somma_business_in,
    SUM(CASE WHEN segno = '+' AND desc_tipo_conto = 'Conto Famiglie' THEN importo ELSE 0 END) AS somma_famiglie_in
FROM db_clienti
GROUP BY id_cliente;

-- INDICATORE 7: TRANSAZIONI IN USCITA PER TIPOLOGIA DI CONTO E SOMMA IMPORTI
DROP TEMPORARY TABLE IF EXISTS transaz_negative_per_tipo_conto;

CREATE TEMPORARY TABLE transaz_negative_per_tipo_conto AS
SELECT
    id_cliente,
    COUNT(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Privati' THEN id_conto END) AS count_privati_out,
    COUNT(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Base' THEN id_conto END) AS count_base_out,
    COUNT(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Business' THEN id_conto END) AS count_business_out,
    COUNT(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Famiglie' THEN id_conto END) AS count_famiglie_out,
    
    SUM(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Privati' THEN importo ELSE 0 END) AS somma_privati_out,
    SUM(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Base' THEN importo ELSE 0 END) AS somma_base_out,
    SUM(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Business' THEN importo ELSE 0 END) AS somma_business_out,
    SUM(CASE WHEN segno = '-' AND desc_tipo_conto = 'Conto Famiglie' THEN importo ELSE 0 END) AS somma_famiglie_out
FROM db_clienti
GROUP BY id_cliente;

SELECT * FROM transaz_negative_per_tipo_conto;
-- CREAZIONE TABELLA FINALE UNIFICATA CON TUTTI GLI INDICATORI
DROP TABLE IF EXISTS db_clienti_completo;

CREATE TABLE db_clienti_completo AS
SELECT
    ec.id_cliente,
    ec.eta,
    tu.num_trans_uscita,
    tu.uscite_tot,
    te.num_trans_entrata,
    te.entrate_tot,
    nc.num_conti,
    tc.conto_privati,
    tc.conto_base,
    tc.conto_business,
    tc.conto_famiglie,
    tp.count_privati_in,
    tp.count_base_in,
    tp.count_business_in,
    tp.count_famiglie_in,
    tp.somma_privati_in,
    tp.somma_base_in,
    tp.somma_business_in,
    tp.somma_famiglie_in,
    tn.count_privati_out,
    tn.count_base_out,
    tn.count_business_out,
    tn.count_famiglie_out,
    tn.somma_privati_out,
    tn.somma_base_out,
    tn.somma_business_out,
    tn.somma_famiglie_out
FROM eta_clienti ec
LEFT JOIN transazioni_uscita tu ON ec.id_cliente = tu.id_cliente
LEFT JOIN transazioni_entrata te ON ec.id_cliente = te.id_cliente
LEFT JOIN numero_conti nc ON ec.id_cliente = nc.id_cliente
LEFT JOIN tipo_conti tc ON ec.id_cliente = tc.id_cliente
LEFT JOIN transaz_positive_per_tipo_conto tp ON ec.id_cliente = tp.id_cliente
LEFT JOIN transaz_negative_per_tipo_conto tn ON ec.id_cliente = tn.id_cliente;


SELECT * FROM db_clienti_completo LIMIT 100;

-- CONTROLLO NUMERO RECORD E CLIENTI DISTINTI
SELECT
    COUNT(*) AS righe_finali,
    COUNT(DISTINCT id_cliente) AS clienti_distinti
FROM db_clienti_completo;


