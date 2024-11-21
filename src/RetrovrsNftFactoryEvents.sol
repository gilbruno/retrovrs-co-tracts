// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract RetrovrsNftFactoryEvents {
 	/**
	 * @dev Emitted when a collection is created
	 */
	event RetrovrsCollectionCreated(
		string _collectionName,
		address _collectionAddress,
		address _creator,
		address _admin
	);
   
}