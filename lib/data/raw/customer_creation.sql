-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 02, 2025 at 10:14 PM
-- Server version: 10.6.22-MariaDB-cll-lve
-- PHP Version: 8.3.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `iwms`
--

-- --------------------------------------------------------

--
-- Table structure for table `customer_creation`
--

CREATE TABLE `customer_creation` (
  `id` int(11) NOT NULL,
  `unique_id` varchar(50) NOT NULL,
  `customer_id` varchar(100) NOT NULL,
  `owner_name` varchar(50) NOT NULL,
  `contact_no` varchar(50) NOT NULL,
  `building_no` varchar(50) NOT NULL,
  `street` varchar(100) NOT NULL,
  `area` varchar(100) NOT NULL,
  `pincode` varchar(50) NOT NULL,
  `city` varchar(100) NOT NULL,
  `district` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `zone` varchar(50) NOT NULL,
  `ward` varchar(50) NOT NULL,
  `property_name` varchar(50) NOT NULL,
  `sub_property` varchar(50) NOT NULL,
  `id_type` varchar(50) NOT NULL,
  `id_no` varchar(50) NOT NULL,
  `lattitude` varchar(50) NOT NULL,
  `longitude` varchar(50) NOT NULL,
  `is_active` int(11) NOT NULL DEFAULT 1,
  `is_delete` int(11) NOT NULL DEFAULT 0,
  `updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created` timestamp NOT NULL DEFAULT current_timestamp(),
  `acc_year` varchar(50) NOT NULL,
  `session_id` varchar(50) NOT NULL,
  `sess_user_type` varchar(50) NOT NULL,
  `sess_user_id` varchar(50) NOT NULL,
  `sess_company_id` varchar(50) NOT NULL,
  `sess_branch_id` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer_creation`
--

INSERT INTO `customer_creation` (`id`, `unique_id`, `customer_id`, `owner_name`, `contact_no`, `building_no`, `street`, `area`, `pincode`, `city`, `district`, `state`, `zone`, `ward`, `property_name`, `sub_property`, `id_type`, `id_no`, `lattitude`, `longitude`, `is_active`, `is_delete`, `updated`, `created`, `acc_year`, `session_id`, `sess_user_type`, `sess_user_id`, `sess_company_id`, `sess_branch_id`) VALUES
(1, 'CUS-67cfb61652f3726811', 'CUS-2503-0001', 'Raju', '6789054321', '12', 'test address', 'testing area', '201301', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedea076b0293526', '667a56d7d682a20681', '6662f7d4d702415431', '1', '887766554433', '28.470768', '77.497594', 1, 0, '2025-03-11 04:03:34', '2025-03-11 04:03:34', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(2, 'CUS-67cfb691ae14918202', 'CUS-2503-0002', 'Jonathan', '7766554433', '89', '2nd street', 'lotus area', '201303', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '6662e6dcbe48512021', '66cc7de48735e37366', '2', 'XYUI67890', '28.478719', '77.519734', 1, 0, '2025-03-11 04:05:37', '2025-03-11 04:05:37', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(3, 'CUS-67cfb789c5a5e93272', 'CUS-2503-0003', 'Larry ', '8899002244', '67', 'buddhar street', 'gandhi Area', '202301', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedec30dc7c38623', '667a559d3d5d446332', '667a56929aece30377', '3', 'BSDE2345I', '28.465138', '77.539647', 1, 0, '2025-03-11 04:09:45', '2025-03-11 04:09:45', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(4, 'CUS-67cfb8554d7d254724', 'CUS-2503-0004', 'DomToretto', '6677889900', '9', 'race street', 'abc', '201304', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '6662f8f0b12ed55284', '6662f8fe1d2ed37836', '1', '332288990011', '28.452763', '77.502139', 1, 0, '2025-03-11 04:13:09', '2025-03-11 04:13:09', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(5, 'CUS-67cfba636099d17503', 'CUS-2503-0005', 'Roman ', '678904321', '678', 'Alpha I', 'Block B ', '201305', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedea076b0293526', '667a56d7d682a20681', '6662f7d4d702415431', '1', '876543219012', '28.475360', '77.508596', 1, 0, '2025-03-11 04:21:55', '2025-03-11 04:21:55', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(6, 'CUS-67cfbafd79ece22865', 'CUS-2503-0006', 'Tej Parki', '7889007547', '78', 'Alpha I', 'Block E', '201302', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '6662e6dcbe48512021', '66cc7de48735e37366', '2', 'JHG4567Y', '28.474078', '77.514524', 1, 0, '2025-03-11 04:24:29', '2025-03-11 04:24:29', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(7, 'CUS-67cfbbd65231051326', 'CUS-2503-0007', 'Lakshmi pabbi', '9007544789', '453', 'Sector Alpha II', 'Pocket I', '201304', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedea076b0293526', '6662f8f0b12ed55284', '6662f8fe1d2ed37836', '2', 'JFGH8997G', '28.476849', '77.519604', 1, 0, '2025-03-11 04:28:06', '2025-03-11 04:28:06', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(8, 'CUS-67cfbcb8a9e5b18067', 'CUS-2503-0008', 'Jack', '6677889933', '987', 'Sector Alpha II', 'Pocket G', '201302', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '6662f8f0b12ed55284', '6662f8fe1d2ed37836', '1', '345678902122', '28.479288', ' 77.513771', 1, 0, '2025-03-11 04:31:52', '2025-03-11 04:31:52', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(9, 'CUS-67cfbd3428af351081', 'CUS-2503-0009', 'Kenny Dev', '9988770055', '345', 'Delta I', 'Block A', '201301', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedec30dc7c38623', '667a559d3d5d446332', '667a56929aece30377', '1', '345678902167', '28.480198', '77.525814', 1, 0, '2025-03-11 04:33:56', '2025-03-11 04:33:56', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(10, 'CUS-67cfbdb50849f81156', 'CUS-2503-0010', 'Kal mohammad', '6655778899', '876', 'Delta I', 'Block E', '201303', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedea076b0293526', '6662e6dcbe48512021', '66cc7de48735e37366', '3', 'LUT3038U', '28.484333', '77.525532', 1, 0, '2025-03-11 04:36:05', '2025-03-11 04:36:05', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(11, 'CUS-67cfbe61a298283879', 'CUS-2503-0011', 'Margarita', '7766544322', '98', 'Delta II', 'Block H', '201302', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '6662e6dcbe48512021', '66cc7de48735e37366', '1', '78890643669', '28.486276', '77.522944', 1, 0, '2025-03-11 04:38:57', '2025-03-11 04:38:57', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(12, 'CUS-67cfbee6ecb6730330', 'CUS-2503-0012', 'Safar', '8877665544', '567', 'Delta II', 'L Block', '201303', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedec30dc7c38623', '667a559d3d5d446332', '667a56929aece30377', '2', 'GTRE4567Y', '28.489522', '77.518428', 1, 0, '2025-03-11 04:41:10', '2025-03-11 04:41:10', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(13, 'CUS-67cfbf6231b5982906', 'CUS-2503-0013', 'Ramsey Ji', '9900555899', '987', 'Beta II', 'Block H', '201303', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede7fe98a648366', '67cededde1ba483065', '667a559d3d5d446332', '667a56929aece30377', '2', 'UYTR376T', '28.487786', '77.510196', 1, 0, '2025-03-11 04:43:14', '2025-03-11 04:43:14', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322'),
(14, 'CUS-67cfc171c4d9645601', 'CUS-2503-0014', 'Sophie Noor', '7788990077', '788', 'Beta II', 'Block F', '201303', 'city602c6d1a4073146513', 'dist602be1ba3978f84855', 'sta5ff56c71b06fc13460', '67cede64f152c96534', '67cedec30dc7c38623', '667a559d3d5d446332', '667a56929aece30377', '2', 'YUITR7865U', '28.481873', '77.513312', 1, 0, '2025-03-11 04:52:01', '2025-03-11 04:52:01', '2024-2025', '88b38df6087e7fa843e9be2de47172ca', '6660505c3d18b50149', '66604f07ae42a24843', 'comp5fa3b1c2a3bab70290', 'bran5fa3b1dced5d363322');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customer_creation`
--
ALTER TABLE `customer_creation`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_id` (`unique_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customer_creation`
--
ALTER TABLE `customer_creation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
