// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;
/**
 * @notice Structure of the NFT
 * certificateAuthenticity: the links to the certificate of authenticity
 */
struct NFT {
    string name;
    string description;
    uint256 price;
    string currency;
    string certificateAuthenticity;
}
