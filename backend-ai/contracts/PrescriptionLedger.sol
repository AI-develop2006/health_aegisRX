// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PrescriptionLedger {
    address public owner;

    struct Prescription {
        bytes32 hash;
        address doctor;
        bool exists;
        bool dispensed;
    }

    // Maps Prescription ID string (e.g. "RX-9921") to its on-chain struct
    mapping(string => Prescription) public prescriptions;

    // Authorized actors mapping
    mapping(address => bool) public authorizedDoctors;
    mapping(address => bool) public authorizedPharmacies;

    event PrescriptionCreated(string indexed id, bytes32 indexed hash, address indexed doctor);
    event PrescriptionDispensed(string indexed id, address indexed pharmacy);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyDoctor() {
        require(authorizedDoctors[msg.sender] || msg.sender == owner, "Not an authorized doctor");
        _;
    }

    modifier onlyPharmacy() {
        require(authorizedPharmacies[msg.sender] || msg.sender == owner, "Not an authorized pharmacy");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedDoctors[msg.sender] = true;
        authorizedPharmacies[msg.sender] = true;
    }

    function setDoctorAuthorization(address doctor, bool status) external onlyOwner {
        authorizedDoctors[doctor] = status;
    }

    function setPharmacyAuthorization(address pharmacy, bool status) external onlyOwner {
        authorizedPharmacies[pharmacy] = status;
    }

    function createPrescription(string calldata id, bytes32 hash) external onlyDoctor {
        require(!prescriptions[id].exists, "Prescription already exists");
        prescriptions[id] = Prescription({
            hash: hash,
            doctor: msg.sender,
            exists: true,
            dispensed: false
        });
        emit PrescriptionCreated(id, hash, msg.sender);
    }

    function markDispensed(string calldata id) external onlyPharmacy {
        require(prescriptions[id].exists, "Prescription does not exist");
        require(!prescriptions[id].dispensed, "Prescription already dispensed");
        prescriptions[id].dispensed = true;
        emit PrescriptionDispensed(id, msg.sender);
    }

    function getPrescription(string calldata id) external view returns (
        bytes32 rxHash,
        address doctor,
        bool exists,
        bool dispensed
    ) {
        Prescription memory rx = prescriptions[id];
        return (rx.hash, rx.doctor, rx.exists, rx.dispensed);
    }
}
