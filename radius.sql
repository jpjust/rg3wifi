-- MySQL dump 10.11
--
-- Host: localhost    Database: radius
-- ------------------------------------------------------
-- Server version	5.0.32-Debian_7etch1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `nas`
--

DROP TABLE IF EXISTS `nas`;
CREATE TABLE `nas` (
  `id` int(10) NOT NULL auto_increment,
  `nasname` varchar(128) NOT NULL default '',
  `shortname` varchar(32) default NULL,
  `type` varchar(30) default 'other',
  `ports` int(5) default NULL,
  `secret` varchar(60) NOT NULL default 'secret',
  `community` varchar(50) default NULL,
  `description` varchar(200) default 'RADIUS Client',
  PRIMARY KEY  (`id`),
  KEY `nasname` (`nasname`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `nas`
--

LOCK TABLES `nas` WRITE;
/*!40000 ALTER TABLE `nas` DISABLE KEYS */;
/*!40000 ALTER TABLE `nas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radacct`
--

DROP TABLE IF EXISTS `radacct`;
CREATE TABLE `radacct` (
  `RadAcctId` bigint(21) NOT NULL auto_increment,
  `AcctSessionId` varchar(32) NOT NULL default '',
  `AcctUniqueId` varchar(32) NOT NULL default '',
  `UserName` varchar(64) NOT NULL default '',
  `Realm` varchar(64) default '',
  `NASIPAddress` varchar(15) NOT NULL default '',
  `NASPortId` varchar(15) default NULL,
  `NASPortType` varchar(32) default NULL,
  `AcctStartTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `AcctStopTime` datetime NOT NULL default '0000-00-00 00:00:00',
  `AcctSessionTime` int(12) default NULL,
  `AcctAuthentic` varchar(32) default NULL,
  `ConnectInfo_start` varchar(50) default NULL,
  `ConnectInfo_stop` varchar(50) default NULL,
  `AcctInputOctets` bigint(12) default NULL,
  `AcctOutputOctets` bigint(12) default NULL,
  `CalledStationId` varchar(50) NOT NULL default '',
  `CallingStationId` varchar(50) NOT NULL default '',
  `AcctTerminateCause` varchar(32) NOT NULL default '',
  `ServiceType` varchar(32) default NULL,
  `FramedProtocol` varchar(32) default NULL,
  `FramedIPAddress` varchar(15) NOT NULL default '',
  `AcctStartDelay` int(12) default NULL,
  `AcctStopDelay` int(12) default NULL,
  PRIMARY KEY  (`RadAcctId`),
  KEY `UserName` (`UserName`),
  KEY `FramedIPAddress` (`FramedIPAddress`),
  KEY `AcctSessionId` (`AcctSessionId`),
  KEY `AcctUniqueId` (`AcctUniqueId`),
  KEY `AcctStartTime` (`AcctStartTime`),
  KEY `AcctStopTime` (`AcctStopTime`),
  KEY `NASIPAddress` (`NASIPAddress`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radacct`
--

LOCK TABLES `radacct` WRITE;
/*!40000 ALTER TABLE `radacct` DISABLE KEYS */;
/*!40000 ALTER TABLE `radacct` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radcheck`
--

DROP TABLE IF EXISTS `radcheck`;
CREATE TABLE `radcheck` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `UserName` varchar(64) NOT NULL default '',
  `Attribute` varchar(32) NOT NULL default '',
  `op` char(2) NOT NULL default '==',
  `Value` varchar(253) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `UserName` (`UserName`(32))
) ENGINE=MyISAM AUTO_INCREMENT=86 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radcheck`
--

LOCK TABLES `radcheck` WRITE;
/*!40000 ALTER TABLE `radcheck` DISABLE KEYS */;
INSERT INTO `radcheck` VALUES (85,'just','Password','==','iecdbp55'),(76,'x','Password','==','x');
/*!40000 ALTER TABLE `radcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupcheck`
--

DROP TABLE IF EXISTS `radgroupcheck`;
CREATE TABLE `radgroupcheck` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `GroupName` varchar(64) NOT NULL default '',
  `Attribute` varchar(32) NOT NULL default '',
  `op` char(2) NOT NULL default '==',
  `Value` varchar(253) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `GroupName` (`GroupName`(32))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radgroupcheck`
--

LOCK TABLES `radgroupcheck` WRITE;
/*!40000 ALTER TABLE `radgroupcheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `radgroupcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupreply`
--

DROP TABLE IF EXISTS `radgroupreply`;
CREATE TABLE `radgroupreply` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `GroupName` varchar(64) NOT NULL default '',
  `Attribute` varchar(32) NOT NULL default '',
  `op` char(2) NOT NULL default '=',
  `Value` varchar(253) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `GroupName` (`GroupName`(32))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radgroupreply`
--

LOCK TABLES `radgroupreply` WRITE;
/*!40000 ALTER TABLE `radgroupreply` DISABLE KEYS */;
/*!40000 ALTER TABLE `radgroupreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radpostauth`
--

DROP TABLE IF EXISTS `radpostauth`;
CREATE TABLE `radpostauth` (
  `id` int(11) NOT NULL auto_increment,
  `user` varchar(64) NOT NULL default '',
  `pass` varchar(64) NOT NULL default '',
  `reply` varchar(32) NOT NULL default '',
  `date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radpostauth`
--

LOCK TABLES `radpostauth` WRITE;
/*!40000 ALTER TABLE `radpostauth` DISABLE KEYS */;
/*!40000 ALTER TABLE `radpostauth` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radreply`
--

DROP TABLE IF EXISTS `radreply`;
CREATE TABLE `radreply` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `UserName` varchar(64) NOT NULL default '',
  `Attribute` varchar(32) NOT NULL default '',
  `op` char(2) NOT NULL default '=',
  `Value` varchar(253) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `UserName` (`UserName`(32))
) ENGINE=MyISAM AUTO_INCREMENT=85 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `radreply`
--

LOCK TABLES `radreply` WRITE;
/*!40000 ALTER TABLE `radreply` DISABLE KEYS */;
INSERT INTO `radreply` VALUES (84,'just','Framed-IP-Address','=','172.16.39.77'),(75,'x','Framed-IP-Address','=','172.16.27.195');
/*!40000 ALTER TABLE `radreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_chamados`
--

DROP TABLE IF EXISTS `rg3_chamados`;
CREATE TABLE `rg3_chamados` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `id_tipo` int(10) unsigned NOT NULL default '0',
  `id_estado` int(10) unsigned NOT NULL default '0',
  `cliente` varchar(50) NOT NULL default '',
  `endereco` varchar(200) NOT NULL default '',
  `telefone` varchar(15) default NULL,
  `motivo` text NOT NULL,
  `observacoes` text,
  `data_chamado` datetime NOT NULL default '0000-00-00 00:00:00',
  `data_conclusao` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `id_tipo` (`id_tipo`),
  KEY `id_estado` (`id_estado`),
  CONSTRAINT `rg3_chamados_ibfk_1` FOREIGN KEY (`id_tipo`) REFERENCES `rg3_chamados_tipo` (`id`),
  CONSTRAINT `rg3_chamados_ibfk_2` FOREIGN KEY (`id_estado`) REFERENCES `rg3_chamados_estado` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_chamados`
--

LOCK TABLES `rg3_chamados` WRITE;
/*!40000 ALTER TABLE `rg3_chamados` DISABLE KEYS */;
INSERT INTO `rg3_chamados` VALUES (0,1,1,'dfdsfsd','fsdfsdfsd',NULL,'fsdfsdfsd',NULL,'2007-07-22 00:16:00',NULL),(2,1,2,'Fulano de Tal','Rua A, n 13',NULL,'Sem sinal.\r\n','Placa de rede ruim.\r\n','2007-07-20 23:26:00','2007-07-20 23:54:00'),(5,1,1,'Teste','Rua X',NULL,'dfgdgdf',NULL,'2007-07-21 23:50:00',NULL),(8,1,1,'Fulano','Rua Y',NULL,'Fudeu!\r\n',NULL,'2007-07-22 00:03:00',NULL),(10,1,1,'sfsdfsdf','sdfsdfsdfsd',NULL,'dfsdfsd',NULL,'2007-07-22 00:16:00',NULL),(11,1,2,'asdas','asdas',NULL,'\'; select * from rg3_usuarios; --','Foi OK!','2007-07-22 14:22:00','2007-07-22 14:24:00'),(12,1,1,'Teste','Teste',NULL,'Teste',NULL,'2007-07-23 20:11:00','1900-00-00 00:00:00');
/*!40000 ALTER TABLE `rg3_chamados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_chamados_estado`
--

DROP TABLE IF EXISTS `rg3_chamados_estado`;
CREATE TABLE `rg3_chamados_estado` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_chamados_estado`
--

LOCK TABLES `rg3_chamados_estado` WRITE;
/*!40000 ALTER TABLE `rg3_chamados_estado` DISABLE KEYS */;
INSERT INTO `rg3_chamados_estado` VALUES (1,'Aberto'),(2,'Finalizado');
/*!40000 ALTER TABLE `rg3_chamados_estado` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_chamados_tipo`
--

DROP TABLE IF EXISTS `rg3_chamados_tipo`;
CREATE TABLE `rg3_chamados_tipo` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_chamados_tipo`
--

LOCK TABLES `rg3_chamados_tipo` WRITE;
/*!40000 ALTER TABLE `rg3_chamados_tipo` DISABLE KEYS */;
INSERT INTO `rg3_chamados_tipo` VALUES (1,'Suporte'),(2,'Estudo de viabilidade'),(3,'Instalacao');
/*!40000 ALTER TABLE `rg3_chamados_tipo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_contas`
--

DROP TABLE IF EXISTS `rg3_contas`;
CREATE TABLE `rg3_contas` (
  `uid` int(10) unsigned NOT NULL auto_increment,
  `id_cliente` int(10) unsigned NOT NULL,
  `id_grupo` int(10) unsigned NOT NULL,
  `id_plano` int(10) unsigned NOT NULL,
  `login` varchar(20) collate latin1_general_ci NOT NULL,
  `senha` varchar(20) collate latin1_general_ci NOT NULL,
  `ip` char(16) collate latin1_general_ci NOT NULL,
  PRIMARY KEY  (`uid`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `ip` (`ip`),
  KEY `id_cliente` (`id_cliente`),
  KEY `id_grupo` (`id_grupo`),
  KEY `id_plano` (`id_plano`),
  CONSTRAINT `rg3_contas_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `rg3_usuarios` (`uid`),
  CONSTRAINT `rg3_contas_ibfk_2` FOREIGN KEY (`id_grupo`) REFERENCES `rg3_grupos` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

--
-- Dumping data for table `rg3_contas`
--

LOCK TABLES `rg3_contas` WRITE;
/*!40000 ALTER TABLE `rg3_contas` DISABLE KEYS */;
INSERT INTO `rg3_contas` VALUES (1,2,3,2,'just','iecdbp55','172.16.39.77'),(6,10,3,1,'a','a','172.16.28.13'),(9,10,3,1,'d','d','172.16.28.254'),(10,10,3,2,'g','g','172.16.40.143'),(11,12,3,1,'x','x','172.16.27.195');
/*!40000 ALTER TABLE `rg3_contas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_fabricantes`
--

DROP TABLE IF EXISTS `rg3_fabricantes`;
CREATE TABLE `rg3_fabricantes` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `nome` (`nome`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_fabricantes`
--

LOCK TABLES `rg3_fabricantes` WRITE;
/*!40000 ALTER TABLE `rg3_fabricantes` DISABLE KEYS */;
INSERT INTO `rg3_fabricantes` VALUES (1,'Teste');
/*!40000 ALTER TABLE `rg3_fabricantes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_grupos`
--

DROP TABLE IF EXISTS `rg3_grupos`;
CREATE TABLE `rg3_grupos` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_grupos`
--

LOCK TABLES `rg3_grupos` WRITE;
/*!40000 ALTER TABLE `rg3_grupos` DISABLE KEYS */;
INSERT INTO `rg3_grupos` VALUES (1,'admin'),(2,'operador'),(3,'cliente');
/*!40000 ALTER TABLE `rg3_grupos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_modelos`
--

DROP TABLE IF EXISTS `rg3_modelos`;
CREATE TABLE `rg3_modelos` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `id_fabricante` int(10) unsigned NOT NULL default '0',
  `nome` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `id_fabricante` (`id_fabricante`),
  CONSTRAINT `rg3_modelos_ibfk_1` FOREIGN KEY (`id_fabricante`) REFERENCES `rg3_fabricantes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_modelos`
--

LOCK TABLES `rg3_modelos` WRITE;
/*!40000 ALTER TABLE `rg3_modelos` DISABLE KEYS */;
INSERT INTO `rg3_modelos` VALUES (1,1,'Teste');
/*!40000 ALTER TABLE `rg3_modelos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_planos`
--

DROP TABLE IF EXISTS `rg3_planos`;
CREATE TABLE `rg3_planos` (
  `id` int(10) unsigned NOT NULL default '0',
  `nome` varchar(50) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_planos`
--

LOCK TABLES `rg3_planos` WRITE;
/*!40000 ALTER TABLE `rg3_planos` DISABLE KEYS */;
INSERT INTO `rg3_planos` VALUES (1,'Basico - 150 Kbps'),(2,'Avancado - 300 Kbps');
/*!40000 ALTER TABLE `rg3_planos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_radios`
--

DROP TABLE IF EXISTS `rg3_radios`;
CREATE TABLE `rg3_radios` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `id_modelo` int(10) unsigned NOT NULL default '0',
  `id_base` int(10) unsigned default '0',
  `id_tipo` int(10) unsigned default '0',
  `mac` varchar(17) NOT NULL default '',
  `data_compra` date NOT NULL default '0000-00-00',
  `data_instalacao` date default '0000-00-00',
  `valor_compra` float NOT NULL default '0',
  `custo` float NOT NULL default '0',
  `localizacao` varchar(255) default NULL,
  `id_banda` int(10) unsigned default '0',
  `id_preambulo` int(10) unsigned default '0',
  `ip` varchar(15) default NULL,
  `essid` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `mac` (`mac`),
  KEY `id_modelo` (`id_modelo`),
  KEY `id_base` (`id_base`),
  KEY `id_tipo` (`id_tipo`),
  KEY `id_banda` (`id_banda`),
  KEY `id_preambulo` (`id_preambulo`),
  CONSTRAINT `rg3_radios_ibfk_3` FOREIGN KEY (`id_modelo`) REFERENCES `rg3_modelos` (`id`),
  CONSTRAINT `rg3_radios_ibfk_4` FOREIGN KEY (`id_base`) REFERENCES `rg3_radios` (`id`),
  CONSTRAINT `rg3_radios_ibfk_5` FOREIGN KEY (`id_tipo`) REFERENCES `rg3_radios_tipo` (`id`),
  CONSTRAINT `rg3_radios_ibfk_6` FOREIGN KEY (`id_banda`) REFERENCES `rg3_radios_banda` (`id`),
  CONSTRAINT `rg3_radios_ibfk_7` FOREIGN KEY (`id_preambulo`) REFERENCES `rg3_radios_preambulo` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_radios`
--

LOCK TABLES `rg3_radios` WRITE;
/*!40000 ALTER TABLE `rg3_radios` DISABLE KEYS */;
INSERT INTO `rg3_radios` VALUES (1,1,NULL,1,'1','2007-07-23',NULL,1,1,NULL,1,1,NULL,NULL);
/*!40000 ALTER TABLE `rg3_radios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_radios_banda`
--

DROP TABLE IF EXISTS `rg3_radios_banda`;
CREATE TABLE `rg3_radios_banda` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_radios_banda`
--

LOCK TABLES `rg3_radios_banda` WRITE;
/*!40000 ALTER TABLE `rg3_radios_banda` DISABLE KEYS */;
INSERT INTO `rg3_radios_banda` VALUES (1,'B'),(2,'G'),(3,'B+G');
/*!40000 ALTER TABLE `rg3_radios_banda` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_radios_preambulo`
--

DROP TABLE IF EXISTS `rg3_radios_preambulo`;
CREATE TABLE `rg3_radios_preambulo` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_radios_preambulo`
--

LOCK TABLES `rg3_radios_preambulo` WRITE;
/*!40000 ALTER TABLE `rg3_radios_preambulo` DISABLE KEYS */;
INSERT INTO `rg3_radios_preambulo` VALUES (1,'Curto'),(2,'Longo');
/*!40000 ALTER TABLE `rg3_radios_preambulo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_radios_tipo`
--

DROP TABLE IF EXISTS `rg3_radios_tipo`;
CREATE TABLE `rg3_radios_tipo` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nome` varchar(20) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_radios_tipo`
--

LOCK TABLES `rg3_radios_tipo` WRITE;
/*!40000 ALTER TABLE `rg3_radios_tipo` DISABLE KEYS */;
INSERT INTO `rg3_radios_tipo` VALUES (1,'Nao instalado'),(2,'Base'),(3,'Estacao');
/*!40000 ALTER TABLE `rg3_radios_tipo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rg3_usuarios`
--

DROP TABLE IF EXISTS `rg3_usuarios`;
CREATE TABLE `rg3_usuarios` (
  `uid` int(10) unsigned NOT NULL auto_increment,
  `id_grupo` int(10) unsigned NOT NULL,
  `bloqueado` tinyint(3) unsigned NOT NULL default '0',
  `nome` varchar(100) NOT NULL default '',
  `data_adesao` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `rg` varchar(20) NOT NULL default '',
  `doc` varchar(20) NOT NULL default '',
  `data_nascimento` date NOT NULL default '0000-00-00',
  `telefone` varchar(20) NOT NULL default '',
  `endereco` varchar(200) NOT NULL default '',
  `bairro` varchar(100) NOT NULL default '',
  `cep` varchar(11) NOT NULL default '',
  `kit_proprio` tinyint(3) unsigned NOT NULL,
  `cabo` int(10) unsigned NOT NULL,
  `valor_instalacao` float unsigned NOT NULL,
  `valor_mensalidade` float unsigned NOT NULL,
  `observacao` text,
  PRIMARY KEY  (`uid`),
  UNIQUE KEY `rg` (`rg`),
  UNIQUE KEY `doc` (`doc`),
  KEY `id_grupo` (`id_grupo`),
  CONSTRAINT `rg3_usuarios_ibfk_1` FOREIGN KEY (`id_grupo`) REFERENCES `rg3_grupos` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `rg3_usuarios`
--

LOCK TABLES `rg3_usuarios` WRITE;
/*!40000 ALTER TABLE `rg3_usuarios` DISABLE KEYS */;
INSERT INTO `rg3_usuarios` VALUES (2,3,0,'JoÃ£o Paulo Just','2007-05-08 14:26:07','09892159-20','008.706.435-92','1982-10-11','(75) 3625-2754','Rua Saracura, 550','Santa Monica','44050-160',0,1,1,1,NULL),(10,3,1,'Teste','2007-07-24 00:45:48','1','2','2007-07-23','2','Teste','Teste','1',0,1,1,1,NULL),(12,3,0,'Cliente Novo','2007-10-24 14:15:34','16756865689','8768768796','2007-10-24','a','a','a','a',0,1,1,1,NULL);
/*!40000 ALTER TABLE `rg3_usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usergroup`
--

DROP TABLE IF EXISTS `usergroup`;
CREATE TABLE `usergroup` (
  `UserName` varchar(64) NOT NULL default '',
  `GroupName` varchar(64) NOT NULL default '',
  `priority` int(11) NOT NULL default '1',
  KEY `UserName` (`UserName`(32))
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `usergroup`
--

LOCK TABLES `usergroup` WRITE;
/*!40000 ALTER TABLE `usergroup` DISABLE KEYS */;
INSERT INTO `usergroup` VALUES ('just','cliente',1),('x','cliente',1);
/*!40000 ALTER TABLE `usergroup` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-10-26 12:33:35
