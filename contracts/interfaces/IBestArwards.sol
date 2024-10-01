// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBestArwards {
    function mintNFT(address recipient, uint256 _tokenType, uint256 _round) external returns (uint256);
}