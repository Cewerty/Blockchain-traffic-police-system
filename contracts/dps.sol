// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.28;

import './Proficoin.sol';

/**
 * @title Dps
 * @author Certyw
 * @notice Простой смарт-контаркт, который является автоматизированной системой управления ДПС
 * @dev Реализация простой АСУП для ДПС, которая реализует функционал регистрации транспортного средства, водительского удостоверения и аккантов водителей и сотрудников ДПС; а также выписывание или оплату штрафов 
 */
contract Dps {

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

    struct transport {
        driverCategory category;
        uint256 marketPrice;
        uint256 explotasionDate;
    }

    struct driverLicense {
        uint256 number;
        uint256 date;
        driverCategory category;
    }

    struct driver {
        string fullName;
        driverLicense license;
        uint256 startDate;
        uint256 unpaidFinesAmount;
        bool registrated;
    }

    mapping(address => driver) public drivers;
    mapping(address => uint256) public balances;
    mapping(address => driver) public dpsWorkers;
    mapping (address => transport[]) public transports;
    mapping(address => uint256[]) public fines;
    mapping(uint256 => address) licenseOwners;
    driverLicense[] registratedLicences;

    constructor() {
        bank = msg.sender;
    }

    modifier onlyDpsWorkers() {
        require(dpsWorkers[msg.sender].registrated == true);
        _;
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

    function sendFine(uint256 licenseNumber) public returns (bool success) {
        require(checkDriverNumber(licenseNumber));
        address driverAddress = licenseOwners[licenseNumber];
        drivers[driverAddress].unpaidFinesAmount++;
        fines[driverAddress].push(block.timestamp);
        return true;
    }
}

