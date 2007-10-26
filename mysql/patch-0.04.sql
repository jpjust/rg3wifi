-- 
-- Estrutura da tabela `rg3_contas`
-- 

CREATE TABLE `rg3_contas` (
  `uid` int(10) unsigned NOT NULL auto_increment,
  `id_cliente` int(10) unsigned NOT NULL,
  `id_grupo` int(10) unsigned NOT NULL,
  `id_plano` int(10) unsigned NOT NULL,
  `login` varchar(20) character set latin1 collate latin1_general_ci NOT NULL,
  `senha` varchar(20) character set latin1 collate latin1_general_ci NOT NULL,
  `ip` char(16) character set latin1 collate latin1_general_ci NOT NULL,
  PRIMARY KEY  (`uid`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `ip` (`ip`),
  KEY `id_cliente` (`id_cliente`),
  KEY `id_grupo` (`id_grupo`),
  KEY `id_plano` (`id_plano`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- 
-- Restrições para a tabela `rg3_contas`
-- 

ALTER TABLE `rg3_contas`
  ADD CONSTRAINT `rg3_contas_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `rg3_usuarios` (`uid`),
  ADD CONSTRAINT `rg3_contas_ibfk_2` FOREIGN KEY (`id_grupo`) REFERENCES `rg3_grupos` (`id`);

--
-- Copia dados para rg3_contas
--

INSERT INTO `rg3_contas` (`id_cliente`, `id_grupo`, `id_plano`, `login`, `senha`, `ip`)
  (SELECT `uid`, `id_grupo`, `id_plano`, `login`, `senha`, `ip` from `rg3_usuarios`);

--
-- Apaga colunas que não são mais necessárias
--

ALTER TABLE `rg3_usuarios` DROP FOREIGN KEY `fk_id_plano`;
ALTER TABLE `rg3_usuarios` DROP INDEX `id_plano`;
ALTER TABLE `rg3_usuarios` DROP `id_plano`;
ALTER TABLE `rg3_usuarios` DROP `login`;
ALTER TABLE `rg3_usuarios` DROP `senha`;
ALTER TABLE `rg3_usuarios` DROP `ip`;
ALTER TABLE `rg3_usuarios` DROP `pppoe`;
ALTER TABLE `rg3_radios` DROP `valor_compra`;
ALTER TABLE `rg3_radios` DROP `custo`;
