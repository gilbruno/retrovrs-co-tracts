// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {RetrovrsNft} from "./RetrovrsNft.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {RetrovrsNftFactoryEvents} from "./RetrovrsNftFactoryEvents.sol";
import {RetrovrsNftFactoryErrors} from "./RetrovrsNftFactoryErrors.sol";
import { AddressZeroError } from "../src/RetrovrsNft.sol";

/**
 * @dev Mandatory parameter for creating invalid collection's character. 
 * (eg. `name of collection (CollectionName), symbol of collection (CollectionSymbol)`)
 */
error InfoCollectionError(bytes32 invalidParam);

error NotExistingDeployer();

error AddressIsAlreadyDeployer();

contract RetrovrsNftFactory is Ownable, AccessControl, RetrovrsNftFactoryEvents {

    bytes32 public constant DEPLOYER_COLLECTION_ROLE = keccak256("DEPLOYER_COLLECTION_ROLE");

    struct CreatedContractCollection{
        RetrovrsNft retrovrsNft;
        string name;
        string symbol;
    }

    address[] private deployerCollections;

    CreatedContractCollection[] private createdContractCollection;

    constructor () Ownable(msg.sender) {
		_grantRole(DEPLOYER_COLLECTION_ROLE, msg.sender);
        deployerCollections.push(msg.sender);
	}

    function createCollection(
        string memory _collectionName, 
		string memory _collectionSymbol,
        address _adminAddress) public onlyRole(DEPLOYER_COLLECTION_ROLE) returns (address createdCollectionAddress_) {
        
        if (bytes(_collectionName).length == 0) revert InfoCollectionError(keccak256("CollectionName"));
        if (bytes(_collectionSymbol).length == 0) revert InfoCollectionError(keccak256("CollectionSymbol"));
        if(_adminAddress == address(0)) revert AddressZeroError(keccak256("AdminAddress"));

        RetrovrsNft retrovrsNft = new RetrovrsNft(_collectionName,_collectionSymbol, _adminAddress);

        CreatedContractCollection memory newRetrovrsCollection;
        newRetrovrsCollection.retrovrsNft = retrovrsNft;
        newRetrovrsCollection.name        = _collectionName;
        newRetrovrsCollection.symbol      = _collectionSymbol;

        createdContractCollection.push(newRetrovrsCollection);

        createdCollectionAddress_ = address(retrovrsNft);

        emit RetrovrsCollectionCreated(_collectionName, createdCollectionAddress_, msg.sender, _adminAddress);
    }

    function removeDeployer(address deployer) private onlyOwner {
        bool deployerFound = false;
        uint lengthDeployerCollections = deployerCollections.length;
        uint indexDeployer;
        for (uint i = 0; i < lengthDeployerCollections; i++) {
            if (deployerCollections[i] == deployer) {
                indexDeployer = i;
                deployerFound = true;
                break;
            }
        }

        if (!deployerFound) {
            revert NotExistingDeployer();
        }
        else {
            delete deployerCollections[indexDeployer];
        }
    }

    function getDeployerCollections() public view  returns (address[] memory) {
        return deployerCollections;
    }

    function getDeployerCollectionsByIndex(uint index) public view  returns (address) {
        return deployerCollections[index];
    }

    function addDeployerCollectionRole(address newDeployer) public onlyOwner {
        if (isDeployerCollectionRole(newDeployer)) {
            revert AddressIsAlreadyDeployer();
        }
        _grantRole(DEPLOYER_COLLECTION_ROLE, newDeployer);
        deployerCollections.push(newDeployer);
	}

 	function revokeDeployerCollectionRole(address deployer) public onlyOwner {
		_revokeRole(DEPLOYER_COLLECTION_ROLE, deployer);
        removeDeployer(deployer);
	}

    function isDeployerCollectionRole(address deployer) public view returns (bool) {
        bool deployerFound = false;
        uint lengthDeployerCollections = deployerCollections.length;
        for (uint i = 0; i < lengthDeployerCollections; i++) {
            if (deployerCollections[i] == deployer) {
                deployerFound = true;
                break;
            }
        }
        return deployerFound;
    }


	function getCreatedNftCollection(uint256 index) public view returns (RetrovrsNft){
		CreatedContractCollection memory contractCollection = createdContractCollection[index];
		return contractCollection.retrovrsNft;
	}

}
