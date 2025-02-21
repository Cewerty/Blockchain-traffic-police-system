// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import './Proficoin.sol';

/**
 * @title Dps
 * @author Certyw
 * @notice Простой смарт-контаркт, который является автоматизированной системой управления ДПС
 * @dev Реализация простой АСУП для ДПС, которая реализует функционал регистрации транспортного средства, водительского удостоверения и аккантов водителей и сотрудников ДПС; а также выписывание или оплату штрафов 
 */
contract TrafficPoliceSystem {

    /**
     * @dev Адрес etherium аккаунта на который будет поступать оплата штрафов от водителей 
     */
    address bank;

    /**
     * @dev Пользовательский тип данных, который используется в структуре водительского удостоверения для определения категории этого удостоверения;
     * в структуре транспорта, характеризуя необходимую для него категорию прав
    */ 
    enum driverCategory {
        A,
        B,
        C
    }

    /**
     * @dev Пользовательский тип данных, представляющий собой транспортное средство
     */
    struct transport {
        driverCategory category;
        uint256 marketPrice;
        uint256 explotasionDate;
    }


    /**
     * @dev Пользовательский тип данных, представляющий собой водительское удостоверение
     */
    struct driverLicense {
        uint256 number;
        uint256 date;
        driverCategory category;
    }


    /**
     * @dev Пользовательский тип данных, представляющий водителя/сотрудника ДПС в зависимости от выбранной роли при регистрации
     */
    struct driver {
        string fullName;
        driverLicense license;
        uint256 startDate;
        uint256 unpaidFinesAmount;
        bool registrated;
    }

    /**
     * @notice Все зарегистрированные водители привязанные к адресам
     * @dev Значения в маппинг добавляются через функцию регистрации, при этом туда добавляются как сотрудники ДПС, так и обычные водители
     */
    mapping(address => driver) public drivers;
    /**
     * @dev Mapping с балансами Proficoins, который используется при оплате штрафов и обновлении лицензии 
     */
    mapping(address => uint256) balances;
    /**
     * @notice Все зарегистрированные водители ДПС
     * @dev В отличии от маппинга drivers сюда добавляются только сотрудники ДПС, потому что только они должны иметь право выписывать штрафы
     */
    mapping(address => driver) public dpsWorkers;
    /**
     * @notice Все зарегистрированные транспортные средства
     * @dev Значения добавляются сюда через функцию registerTransport 
     */
    mapping(address => transport[]) public transports;
    /**
     * @notice Все штрафы выписанные штрафы, привязанные к адресу Ethereum
     * @dev Значения добавляются сюда, используя адреса, указанные в licenseOwners,
     * потому что штрафы выписываются не по адресу, а по номеру водительского удостоверения
     */
    mapping(address => uint256[]) public fines;
    /**
     * @dev Маппинг, который используется для связи номеров водительских удостоверений и адресов сети Ethereum для выписки штрафов
     */
    mapping(uint256 => address) licenseOwners;
    /**
     * @dev Массив со всеми зарегестрированными в базе значениями 
     */
    driverLicense[] registratedLicences;

    constructor() {
        bank = msg.sender;
    }

    /**
     * @notice Проверяет является ли пользователь сотрудником ДПС
     * @dev Проверяет наличие адреса вызывающего контракта в мапе с адресами сотрудников ДПС
     */
    modifier onlyDpsWorkers() {
        require(dpsWorkers[msg.sender].registrated == true);
        _;
    }

    function balanceOf(address userAddress) public view returns (uint256 amount) {
        return balances[userAddress];
    } 
    
    function setBalance(address userAddress, uint256 amount) public {
        balances[userAddress] = amount;
    }

    function checkDriverLicense(uint256 driverNumber, uint256 driverDate, uint256 licenseCategory) view internal returns (bool success) {
        for (uint256 i; i < registratedLicences.length; i++) {
            if (registratedLicences[i].number == driverNumber && registratedLicences[i].date == driverDate && registratedLicences[i].category == driverCategory(licenseCategory)) {
                return true;
            }
        }
        return false;
    }

    function checkDriverNumber(uint driverNumber) view internal returns (bool success) {
        for (uint256 i; i < registratedLicences.length; i++) {
            if (registratedLicences[i].number == driverNumber) {
                return true;
            }
        }
        return false;
    }

    function applyDriverLicense(uint256 driverNumber, uint256 driverDate, uint256 licenseCategory) public returns (bool success) {
        require(checkDriverLicense(driverNumber, driverDate, licenseCategory));
        require(drivers[msg.sender].registrated == true);
        driverCategory category = driverCategory(licenseCategory);
        driverLicense memory license = driverLicense({
            number: driverNumber,
            date: driverDate,
            category: category
        });

        drivers[msg.sender].license = license;
        licenseOwners[driverNumber] = msg.sender;

        return true;
    }

    function registerTransport(uint256 transportCategory, uint256 transportMarketPrice, uint256 transportExplotasionDate ) public returns (bool success) {
        require(drivers[msg.sender].registrated == true);
        require(drivers[msg.sender].license.category == driverCategory(transportCategory));
        require(drivers[msg.sender].unpaidFinesAmount == 0);
        driverCategory category = driverCategory(transportCategory);
        transports[msg.sender].push(transport({
            category: category,
            marketPrice: transportMarketPrice,
            explotasionDate: transportExplotasionDate
        }));
        return true;
    }

    function extendDriverLicense() public returns (bool success){
        require(fines[msg.sender].length == 0);
        require((block.timestamp - drivers[msg.sender].license.date) < 30 days);
        drivers[msg.sender].license.date = block.timestamp;
        return true;
    }

    function payFines(uint256 finesIndex) public returns (bool success) {
        require(fines[msg.sender].length < finesIndex);
        uint256 finesPrice = (block.timestamp - fines[msg.sender][finesIndex]) <= 5 minutes ? 5 : 10;
        require(balances[msg.sender] >= finesPrice);
        balances[bank] += finesPrice;
        delete fines[msg.sender][finesIndex];
        return true;
    }

    function finesAmount(uint256 finesIndex) public view returns(uint256 amount) {
        require(fines[msg.sender].length < finesIndex);
        return (block.timestamp - fines[msg.sender][finesIndex]) <= 5 minutes ? 5 : 10;
    }

    function sendFine(uint256 licenseNumber) public onlyDpsWorkers() returns (bool success) {
        require(checkDriverNumber(licenseNumber));
        address driverAddress = licenseOwners[licenseNumber];
        drivers[driverAddress].unpaidFinesAmount++;
        fines[driverAddress].push(block.timestamp);
        return true;
    }

    // TO-DO: Создать функцию для первичной регистрации пользователя в системе, как сотрудника ДПС, так и обычного водителя
}

