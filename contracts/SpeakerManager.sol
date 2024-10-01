// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SpeakerManager is  Ownable {
    // Cấu trúc lưu trữ thông tin của một seminar
    struct Speaker {
        string name;        // Tên của seminar
        uint256[] seminarId;
    }
    
    mapping(address => bool) public isAdmin;
    mapping(address => Speaker) public addressToSpeaker;

    modifier onlyAdmin() {
        require(isAdmin[_msgSender()] || msg.sender == owner(), "Invalid admin!");
        _;
    }

    constructor()  {}

    function setSpeaker(address _address, Speaker memory _speaker) public onlyAdmin() {
        addressToSpeaker[_address] = _speaker;
    }

    function updateSpeakerName(address _address, string memory _speakerName) public onlyAdmin() {
        addressToSpeaker[_address].name = _speakerName;
    }

    function addSpeakerSeminar(address _address, uint256 _seminarId) public onlyAdmin() {
        addressToSpeaker[_address].seminarId.push(_seminarId);
    }

    function updateSpeakerSeminar(address _address, uint256 _index, uint256 _seminarId) public onlyAdmin() {
        addressToSpeaker[_address].seminarId[_index] = _seminarId;
    }

    function toggleAdmin(address _admin) external onlyOwner() {
        bool _isAdmin = isAdmin[_admin];
        isAdmin[_admin] = !_isAdmin;
    }
}
