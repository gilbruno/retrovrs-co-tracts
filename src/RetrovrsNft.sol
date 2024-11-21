// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from"openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControlDefaultAdminRules} from "openzeppelin-contracts/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {AddressZeroError, EmailRequiredError, BuyerAlreadyOwnsTokenId} from "./RetrovrsNftErrors.sol";
import {RetrovrsNftEvents} from "./RetrovrsNftEvents.sol";
import {NFT} from "./NftStruct.sol";
import {ArrayUtils} from "./ArrayUtils.sol";

struct ItemOwner {
    string firstName;
    string lastName;
    string email;
    address publicKey;
}

contract RetrovrsNft is ERC721URIStorage, AccessControlDefaultAdminRules, RetrovrsNftEvents {

    using ArrayUtils for uint[];

    uint256 private s_tokenId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    NFT[] private s_collection;

    address[] private s_minters;

    mapping(uint => ItemOwner) private s_ownerOfTokenId;

    mapping(string => uint256[]) private s_tokenIdsOfOwnerEmail;
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _adminAddress
    ) ERC721(_name, _symbol) AccessControlDefaultAdminRules(1 days, _adminAddress) {
        if(_adminAddress == address(0)) revert AddressZeroError(keccak256("AdminAddress"));
        _grantRole(MINTER_ROLE, _adminAddress);
        s_minters.push(_adminAddress);
    }

    /**
     * @dev Check for the function 'addOwnerForTokenId'.
     * The email of the new owner is absolutely required
     */
    modifier checkAddOwnerForTokenId(ItemOwner memory newOwner) {
        if (bytes(newOwner.email).length == 0) revert EmailRequiredError();
        _;
    }

    /**
     *  @notice Mint a NFT in the collection
     *  @param _tokenURI Token
     *  @param _nft Description of the NFT
     */
    function mintNFT(
        string memory _tokenURI, 
        NFT memory _nft
    ) external onlyRole(MINTER_ROLE) returns (uint256 newItemId_) {
        s_tokenId += 1;
        s_collection.push(_nft );
        newItemId_ = s_tokenId;
        _mint(msg.sender, newItemId_);
        _setTokenURI(newItemId_, _tokenURI);
        emit RetrovrsNftMined(_nft.name, _nft.price, s_tokenId, _tokenURI);
    }

    /** 
     *  @dev Modifier le propriétaire d'un tokenId
     *  @param tokenId id of token
     *  @param newOwner infos about new owner
     */
    function addOwnerForTokenId(uint tokenId, ItemOwner memory newOwner) external onlyRole(MINTER_ROLE) checkAddOwnerForTokenId(newOwner) {
        // Get the old owner
        ItemOwner memory oldOwner = s_ownerOfTokenId[tokenId];
        if (buyerOwnsTokenId(tokenId, newOwner)) revert BuyerAlreadyOwnsTokenId();
        // Update the owner of the tokenId
        s_ownerOfTokenId[tokenId] = newOwner;
        
        // If the old owner exists, remove the tokenId of the old owner
        if (bytes(oldOwner.email).length != 0) {
            uint256[] storage oldOwnerTokenIds = s_tokenIdsOfOwnerEmail[oldOwner.email];
            uint256 length = oldOwnerTokenIds.length;
            for (uint256 i = 0; i < length; i++) {
                if (oldOwnerTokenIds[i] == tokenId) {
                    oldOwnerTokenIds[i] = oldOwnerTokenIds[length - 1];
                    oldOwnerTokenIds.pop();
                    break;
                }
            }
        }
        
        // Add the tokenId of the new owner
        s_tokenIdsOfOwnerEmail[newOwner.email].push(tokenId);
    }    

    function deleteOwner(uint tokenId, ItemOwner calldata itemOwner) external onlyRole(MINTER_ROLE) {
        //Get tokenIds owned by owner
        uint[] storage arrayOfTokenIds = s_tokenIdsOfOwnerEmail[itemOwner.email];
        uint length = arrayOfTokenIds.length;
        uint indexToDelete;
        //Delete the record in the mapping "s_ownerOfTokenId"
        for (uint i = 0; i < length; i++) {
            if (tokenId == arrayOfTokenIds[i]) {
                indexToDelete = i;
                delete s_ownerOfTokenId[arrayOfTokenIds[i]];
            }
        }    
        //Delete the record in array of the value in the mapping "s_tokenIdsOfOwnerEmail"
        arrayOfTokenIds.deleteElement(indexToDelete);
        
    }    

    
    /**
     *  @dev  Returns true if the buyer owns the tokenId
     *  
     */
    function buyerOwnsTokenId(uint tokenId, ItemOwner memory itemOwner) public view returns (bool){
        uint[] memory tokenIds = getTokenIdsOwnedByEmail(itemOwner.email);
        uint length = tokenIds.length;
        bool result = false;
        for (uint i = 0; i < length; i++) {
            if (tokenId == tokenIds[i]) {
                return true; 
            }
        }
        return result;
    }

    function getOwnerOfTokenId(uint tokenId) public view returns (ItemOwner memory) {
        return s_ownerOfTokenId[tokenId];
    }

    function getTokenIdsOwnedByEmail(string memory email) public view returns (uint[] memory) {
        return s_tokenIdsOfOwnerEmail[email];
    }

    /** 
     *  @dev Getter for "s_minters" array
     */
    function getMinters() public view returns (address[] memory) {
        return s_minters;
    }

    /** 
     *  @dev Get the minter address by index
     */
    function getMinter(uint index) public view returns (address){
        return s_minters[index];
    }

    /** 
     *  @dev Getter for "s_collection" array
     */
    function getCollections() public view returns (NFT[] memory){
        return s_collection;
    }

    /** 
     *  @dev Get the NFT by providing index in the NFT Collection array
     */
    function getCollection(uint index) public view returns (NFT memory){
        return s_collection[index];
    }

    /** 
     *  @dev Getter for "s_tokenId"
     */
    function getTokenId() public view returns (uint256){
        return s_tokenId;
    }

    /**
     * 
     * @notice Add minter role
     */
    function addMinterRole(address minter) public onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, minter);
        s_minters.push(minter);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlDefaultAdminRules, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}