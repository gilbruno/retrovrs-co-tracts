// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test, console } from "forge-std/Test.sol";
import {RetrovrsNft, NFT, ItemOwner} from "../src/RetrovrsNft.sol";
import {RetrovrsNftFactory} from "../src/RetrovrsNftFactory.sol";
import { AddressZeroError, EmailRequiredError, BuyerAlreadyOwnsTokenId } from "../src/RetrovrsNft.sol";
import { InfoCollectionError, NotExistingDeployer, AddressIsAlreadyDeployer } from "../src/RetrovrsNftFactory.sol";
import { IAccessControlDefaultAdminRules } from "openzeppelin-contracts/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
contract RetrovrsNftTest is Test {

    RetrovrsNftFactory public factory;
    RetrovrsNft public nftCollection;

    string private constant COLLECTION_NAME_1 = "Luxury Bags";
    string private constant COLLECTION_NAME_2 = "Luxury Watches";
    string private constant COLLECTION_SYMBOL_1 = "LUXBAGS";
    string private constant COLLECTION_SYMBOL_2 = "LUXWATCHES";

    string private constant NFT_NAME_1 = "Sac_Hermes_1";
    string private constant NFT_DESC_1 = "Sac_Hermes_1 Desc";
    string private constant NFT_NAME_2 = "Sac_Hermes_2";
    string private constant NFT_DESC_2 = "Sac_Hermes_2 Desc";
    uint private constant PRICE_1      = 2000;
    uint private constant PRICE_2      = 5000;
    string private constant CURRENCY   = "USD"; 
    string private constant CERTIFICATE_AUTHENTICITY = "Certificate OK";
    string private constant CERTIFICATE_AUTHENTICITY_2 = "Certificate OK 2";

    address DEPLOYER_FACTORY    = makeAddr("deployer_factory");
    address DEPLOYER_COLLECTION = makeAddr("deployer_collection");
    address ADMIN_COLLECTION_1 = makeAddr("admin_collection_1");
    address ADMIN_COLLECTION_2 = makeAddr("admin_collection_2");
    address USER               = makeAddr("user");
    address USER_2             = makeAddr("user_2");
    address OWNER_1            = makeAddr("owner_1");
    address OWNER_2            = makeAddr("owner_2");

    bytes32 public constant DEPLOYER_COLLECTION_ROLE = keccak256("DEPLOYER_COLLECTION_ROLE");

    uint256 private constant STARTING_BALANCE_ETH = 10 ether;
    string private constant EMPTY_COLLECTION_NAME = "";
    string private constant EMPTY_COLLECTION_SYMBOL = "";

    address private constant ZERO_ADDR = address(0);
    string private constant TOKEN_URI = 'https://ipfs.io/Qnytyuio';
    string private constant TOKEN_URI_2 = 'https://ipfs.io/Qnytyuio2';

    bytes private selectorAddressZeroErrorAdmin = abi.encodeWithSelector(AddressZeroError.selector, keccak256("AdminAddress"));
    bytes private selectorCollectionNameError = abi.encodeWithSelector(InfoCollectionError.selector, keccak256("CollectionName"));
    bytes private selectorCollectionSymbolError = abi.encodeWithSelector(InfoCollectionError.selector, keccak256("CollectionSymbol"));

    ItemOwner itemOwner1 = ItemOwner('John', 'Doe', 'jdoe@gmail.com', address(0));
    ItemOwner itemOwner2 = ItemOwner('Jean', 'Dole', 'jdole@gmail.com', address(0));
    ItemOwner itemOwnerWithoutEmail = ItemOwner('John', 'Doe', '', address(0));

    function setUp() public {
        vm.deal(DEPLOYER_FACTORY, STARTING_BALANCE_ETH);
        vm.deal(ADMIN_COLLECTION_1, STARTING_BALANCE_ETH);
        vm.deal(ADMIN_COLLECTION_2, STARTING_BALANCE_ETH);
    }

    function testOnlyOwnerCanDeployCollection() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        assertNotEq(address(factory), address(0));
    }

    function testSimpleUserCanNotDeployCollection() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.stopPrank();

        deal(USER, STARTING_BALANCE_ETH);
        vm.expectRevert();
        vm.prank(USER);
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, USER);
    }

        function testOnlyOwnerCanGrantDeployerRole() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
    }

    function testDeployerRoleIsCorrectAfterGrant() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
        assertEq(factory.hasRole(DEPLOYER_COLLECTION_ROLE, USER), true);
    }

    function testDeployerRoleIsCorrectAfterGrant2() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
        assertEq(factory.hasRole(DEPLOYER_COLLECTION_ROLE, USER_2), false);
    }

    function testDeployerRoleArrayIsCorrectAfterAddDeployer() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.stopPrank();
        //After only a deployment, the owner of the SC is a deployer, so there is 1 element in the array
        assertEq(factory.getDeployerCollections().length, 1);
    }

    function testDeployerRoleArrayIsCorrectAfterAddDeployer2() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
        //After only a deployment, the owner of the SC is a deployer, so there are 2 elements in the array
        assertEq(factory.getDeployerCollections().length, 2);
    }

    function testDeployerRoleArrayIsCorrectAfterAddDeployer3() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        factory.addDeployerCollectionRole(USER_2);
        vm.stopPrank();
        assertEq(factory.getDeployerCollections().length, 3);

        vm.startPrank(DEPLOYER_FACTORY);
        factory.revokeDeployerCollectionRole(USER_2);
        vm.stopPrank();
        //The array length is still 3 because using 'delete' in an array do not change the array length
        assertEq(factory.getDeployerCollections().length, 3);
    }

    function testDeployerRoleCannotAddSameDeployer() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.expectRevert(AddressIsAlreadyDeployer.selector);
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
    }

    function testDeployerRoleCannotRevokeANonDeployer() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.expectRevert(NotExistingDeployer.selector);
        factory.revokeDeployerCollectionRole(USER_2);
        vm.stopPrank();
    }

    function testIsDeployerRoleIsCorrectAfterAddDeployer() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
        assertEq(factory.isDeployerCollectionRole(USER), true);
    }

    function testIsDeployerRoleIsCorrectAfterAddDeployer2() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();
        assertEq(factory.isDeployerCollectionRole(USER_2), false);
    }

    function testOnlyDeployerCanDeployAfterGrantByOwner() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();

        vm.startPrank(USER);
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, USER);
        vm.stopPrank();
        
    }
    
    function testOnlyDeployerCanDeployAfterGrantByOwner2() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.addDeployerCollectionRole(USER);
        vm.stopPrank();

        deal(USER_2, STARTING_BALANCE_ETH);
        vm.expectRevert();
        vm.startPrank(USER_2);
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, USER);
        vm.stopPrank();
        
    }

    function testRevertsIfAdminAddressIsZeroAddress() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.expectRevert(selectorAddressZeroErrorAdmin);
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ZERO_ADDR);
        vm.stopPrank();
    }

    function testRevertsIfCollectionNameIsEmpty() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.expectRevert(selectorCollectionNameError);
        factory.createCollection(EMPTY_COLLECTION_NAME, COLLECTION_SYMBOL_1, USER);
        vm.stopPrank();
    }

    function testRevertsIfCollectionSymbolIsEmpty() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.expectRevert(selectorCollectionSymbolError);
        factory.createCollection(COLLECTION_NAME_1, EMPTY_COLLECTION_SYMBOL, USER);
        vm.stopPrank();
    }

    function testRevokeAdminRole() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.expectRevert(NotExistingDeployer.selector);
        factory.revokeDeployerCollectionRole(USER);
        vm.stopPrank();
    }

    /****** TEST for "RetrovrsNft" Smart contract  */
    function testNftCollectionRevertsIfAdminAddressIsZeroAddress() public {
        vm.startPrank(DEPLOYER_COLLECTION);
        bytes memory selectorAccessControlInvalidDefaultAdmin = abi.encodeWithSelector(IAccessControlDefaultAdminRules.AccessControlInvalidDefaultAdmin.selector, ZERO_ADDR);
        vm.expectRevert(selectorAccessControlInvalidDefaultAdmin);
        nftCollection = new RetrovrsNft(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ZERO_ADDR);
        vm.stopPrank();
    }

    function testDataStructureNftCollectionLength() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        assertEq(nftCollection.getCollections().length, 1);
    }


    function testDataStructureNftCollectionDataName() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);

        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        NFT memory myNFT = nftCollection.getCollection(0);
        assertEq(myNFT.name, nft1.name);
    }

    function testDataStructureCollectionDataDescription() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);

        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        NFT memory myNFT = nftCollection.getCollection(0);
        assertEq(myNFT.description, nft1.description);
    }

    function testDataStructureCollectionDataPrice() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);

        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        NFT memory myNFT = nftCollection.getCollection(0);
        assertEq(myNFT.price, nft1.price);
    }

    function testDataStructureCollectionDataCertificateAuthenticity() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);

        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        NFT memory myNFT = nftCollection.getCollection(0);
        assertEq(myNFT.certificateAuthenticity, nft1.certificateAuthenticity);
    }

    function testTokenIdAfterMinting() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        assertEq(nftCollection.getTokenId(), 1);
    }

    function testTokenUriAfterMinting() public {
         NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        vm.stopPrank();

        assertEq(nftCollection.tokenURI(nftCollection.getTokenId()), TOKEN_URI);
    }

    function testMintersArrayIsOK() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        vm.stopPrank();

        address[] memory minters = nftCollection.getMinters();
        assertEq(minters.length, 1);
    }

    function testMintersArrayIsOK2() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        vm.stopPrank();

        address[] memory minters = nftCollection.getMinters();
        assertEq(ADMIN_COLLECTION_1, minters[0]);
    }

    function testOriginMinterCanAddMinterRole() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.addMinterRole(USER);
        vm.stopPrank();

        address[] memory minters = nftCollection.getMinters();
        assertEq(minters.length, 2);
    }

    function testRevertsIfAdmincollectionAddressIsZeroAddress() public {
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        vm.expectRevert(selectorAddressZeroErrorAdmin);
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ZERO_ADDR);
        vm.stopPrank();
    }

    function testFirstNameOwnerOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.firstName, itemOwner1.firstName);
    }

    function testLastNameOwnerOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.lastName, itemOwner1.lastName);
    }

    function testEmailOwnerOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.email, itemOwner1.email);
    }

    function testPublicKeyOwnerOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.publicKey, itemOwner1.publicKey);
    }

    function testBuyerOfOneItemIsOnlyOwnerOfOneTokenId() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);
        uint[] memory arrayTokenIds =  nftCollection.getTokenIdsOwnedByEmail(newOwner.email);

        assertEq(arrayTokenIds[0], lastTokenId);
        assertEq(arrayTokenIds.length, 1);
    }

    function testBuyerOfTwoItemsIsOwnerOfTwoTokenIds() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        NFT memory nft2 = NFT(NFT_NAME_2, NFT_DESC_2, PRICE_2, CURRENCY, CERTIFICATE_AUTHENTICITY_2);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        uint tokenId_2;
        
        //The admin mints the NFT #1 and associate to the buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        vm.stopPrank();

        //The admin mints the NFT #2 and associate to the same buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI_2, nft2);
        tokenId_2 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner1);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(tokenId_2);
        uint[] memory arrayTokenIds =  nftCollection.getTokenIdsOwnedByEmail(newOwner.email);

        //Check that the 'itemOwner1' owns the 2 tokenIds
        assertEq(arrayTokenIds[0], tokenId_1);
        assertEq(arrayTokenIds[1], tokenId_2);
        assertEq(arrayTokenIds.length, 2);
    }

    /**
     * @dev Checks data structure in case of NFT minting without any buyer
     */
    function testMintNftWithNoBuyer() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        
        //The admin mints the NFT #1 and associate it with any buyer (so just mint the NFT)
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        console.log('tokenId_1 : ', tokenId_1);
        tokenId_1 = nftCollection.getTokenId();
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(tokenId_1);
        uint[] memory arrayTokenIds =  nftCollection.getTokenIdsOwnedByEmail(newOwner.email);

        //Check that the 'itemOwner1' owns any tokenId
        assertEq(arrayTokenIds.length, 0);
    }

    /**
     * @dev Checks that email is absolutely required to associate a NFT with a buyer
     */
    function testEmailBuyerRequiredToAssociateNftWithBuyer() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        
        //The admin mints the NFT #1 and associate it with any buyer (so just mint the NFT)
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        vm.expectRevert(EmailRequiredError.selector);
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwnerWithoutEmail);
        vm.stopPrank();


    }

    /**
     * @dev Checks data structure if we want to modify infos on a buyer/owner
     *  In order to do that, we delete the owner with obsolete indfosand we addit again 
     */
    function testModifyingBuyerInfos() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        
        //The admin mints the NFT #1 and associate to the buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        tokenId_1 = nftCollection.getTokenId();
        vm.stopPrank();

        assertEq(itemOwner1.publicKey, address(0));

        //The admin modifies the public key of the buyer 'itemOwner1' 
        ItemOwner memory newItemOwner = itemOwner1;
        newItemOwner.publicKey = OWNER_1;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection.deleteOwner(tokenId_1, itemOwner1);
        nftCollection.addOwnerForTokenId(tokenId_1, newItemOwner);
        vm.stopPrank();

        ItemOwner memory owner = nftCollection.getOwnerOfTokenId(tokenId_1);
        uint[] memory tokenIds = nftCollection.getTokenIdsOwnedByEmail(owner.email);
        
        //Check that the new address of 'itemOwner1' has been actually  modified
        assertEq(newItemOwner.publicKey, OWNER_1);
        //Check that the owner still owns 1 tokenId
        assertEq(tokenIds.length, 1);
    }

    /**
     * @dev We test this scenario : 
     *  A buyer #1 buys 2 items, so he owns 2 tokenIds
     *  A buyer #2 buys the second item/tokenId
     *  So the buyer #1 owns only 1 tokenID : the first
     *  So the buyer #2 owns only 1 tokenID : the second
     *  
     */
    function testDifferentBuyers() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        NFT memory nft2 = NFT(NFT_NAME_2, NFT_DESC_2, PRICE_2, CURRENCY, CERTIFICATE_AUTHENTICITY_2);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        uint tokenId_2;
        
        //The admin mints the NFT #1 and associate to the buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        vm.stopPrank();

        //The admin mints the NFT #2 and associate to the same buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI_2, nft2);
        tokenId_2 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner1);
        vm.stopPrank();

        //The admin modifies the owner of the NFT #2 = associates to the 'itemOwner2'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner2);
        vm.stopPrank();

        ItemOwner memory ownerOfTokenId1 = nftCollection.getOwnerOfTokenId(tokenId_1);
        ItemOwner memory ownerOfTokenId2 = nftCollection.getOwnerOfTokenId(tokenId_2);

        uint[] memory arrayTokenIds_owner1 =  nftCollection.getTokenIdsOwnedByEmail(itemOwner1.email);
        uint[] memory arrayTokenIds_owner2 =  nftCollection.getTokenIdsOwnedByEmail(itemOwner2.email);

        //Check that the 'itemOwner1' owns the tokenId #1
        //Check that the 'itemOwner2' owns the tokenId #2
        assertEq(arrayTokenIds_owner1[0], tokenId_1);
        assertEq(arrayTokenIds_owner2[0], tokenId_2);
        assertEq(arrayTokenIds_owner1.length, 1);
        assertEq(arrayTokenIds_owner2.length, 1);
        assertEq(ownerOfTokenId1.firstName, itemOwner1.firstName);
        assertEq(ownerOfTokenId2.firstName, itemOwner2.firstName);
        assertEq(ownerOfTokenId1.lastName, itemOwner1.lastName);
        assertEq(ownerOfTokenId2.lastName, itemOwner2.lastName);
        assertEq(ownerOfTokenId1.email, itemOwner1.email);
        assertEq(ownerOfTokenId2.email, itemOwner2.email);
        assertEq(ownerOfTokenId1.publicKey, itemOwner1.publicKey);
        assertEq(ownerOfTokenId2.publicKey, itemOwner2.publicKey);

    }

    function testSecondOwnerFirstNameOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner2);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.firstName, itemOwner2.firstName);
    }

    function testSecondOwnerLastNameOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner2);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.lastName, itemOwner2.lastName);
    }

    function testSecondOwnerEmailOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner2);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.email, itemOwner2.email);
    }

    function testSecondOwnerPublicKeyOk() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint lastTokenId;
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        lastTokenId = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner1);
        nftCollection.addOwnerForTokenId(lastTokenId, itemOwner2);
        vm.stopPrank();

        ItemOwner memory newOwner = nftCollection.getOwnerOfTokenId(lastTokenId);

        assertEq(newOwner.publicKey, itemOwner2.publicKey);
    }

    /**
     * @dev Checks data structure if we want to modify infos on a buyer/owner
     *  In order to do that, we delete the owner with obsolete indfosand we addit again 
     */
    function testDeleteOwnerForTokenId() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        NFT memory nft2 = NFT(NFT_NAME_2, NFT_DESC_2, PRICE_2, CURRENCY, CERTIFICATE_AUTHENTICITY_2);

        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        uint tokenId_2;

        //The admin mints the NFT #1 & #2 and associate these 2 NFTs to the buyer 'itemOwner1'
        // So the buyer # buys 2 items
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        nftCollection.mintNFT(TOKEN_URI_2, nft2);
        tokenId_2 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner1);
        vm.stopPrank();

        uint[] memory tokenIds = nftCollection.getTokenIdsOwnedByEmail(itemOwner1.email);

        //The buyer #1 owns 2 items
        assertEq(tokenIds.length, 2);

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection.deleteOwner(tokenId_2, itemOwner1);
        vm.stopPrank();

        tokenIds = nftCollection.getTokenIdsOwnedByEmail(itemOwner1.email);
        //The buyer #1 owns now only 1 item
        assertEq(tokenIds.length, 1);
    }

    /**
     * @dev Checks data structure if we want to modify infos on a buyer/owner
     *  In order to do that, we delete the owner with obsolete indfosand we addit again 
     */
    function testDeleteOwnerForTokenId2() public {
        /*
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();
        uint tokenId_1;
        uint tokenId_2;

        //The admin mints the NFT #1 & #2 and associate these 2 NFTs to the buyer 'itemOwner1'
        // So the buyer # buys 2 items
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        nftCollection.mintNFT(TOKEN_URI_2, nft1);
        tokenId_2 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner1);
        vm.stopPrank();

        uint[] memory tokenIds_owner1 = nftCollection.getTokenIdsOwnedByEmail(itemOwner1.email);

        //The admin mints the NFT #3 and associate this 2 NFTs to the buyer 'itemOwner2'
        // So the buyer # buys 2 items
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        nftCollection.mintNFT(TOKEN_URI_2, nft1);
        tokenId_2 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_2, itemOwner1);
        vm.stopPrank();


        //The buyer #1 owns 2 items
        assertEq(tokenIds.length, 2);

        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection.deleteOwner(tokenId_2, itemOwner1);
        vm.stopPrank();

        tokenIds = nftCollection.getTokenIdsOwnedByEmail(itemOwner1.email);
        //The buyer #1 owns now only 1 item
        assertEq(tokenIds.length, 1);
        */
    }

/**
     * @dev Checks data structure if we want to modify infos on a buyer/owner
     *  In order to do that, we delete the owner with obsolete indfosand we addit again 
     */
    function testAdminCannotAddBuyerTwiceForSameTokenId() public {
        NFT memory nft1 = NFT(NFT_NAME_1, NFT_DESC_1, PRICE_1, CURRENCY, CERTIFICATE_AUTHENTICITY);
        
        vm.startPrank(DEPLOYER_FACTORY);
        factory = new RetrovrsNftFactory();
        factory.createCollection(COLLECTION_NAME_1, COLLECTION_SYMBOL_1, ADMIN_COLLECTION_1);
        vm.stopPrank();

        uint tokenId_1;
        //The admin mints the NFT #1 and tries to associate this NFT twice for the same buyer 'itemOwner1'
        vm.startPrank(ADMIN_COLLECTION_1);
        nftCollection = factory.getCreatedNftCollection(0);
        nftCollection.mintNFT(TOKEN_URI, nft1);
        tokenId_1 = nftCollection.getTokenId();
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        vm.expectRevert(BuyerAlreadyOwnsTokenId.selector);
        nftCollection.addOwnerForTokenId(tokenId_1, itemOwner1);
        vm.stopPrank();


    }    

}

