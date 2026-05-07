// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {
    struct Listing {
        address seller;
        uint256 price;
        bool listed;
    }

    mapping(address => mapping(uint256 => Listing)) private _listings;

    event ItemListed(
        address nftContract,
        uint256 tokenId,
        address seller,
        uint256 price
    );

    event ItemSold(
        address nftContract,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price
    );

    event ListingCancelled(
        address nftContract,
        uint256 tokenId,
        address seller
    );

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public {
        require(price > 0, "Price must be greater than 0");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You must own the NFT"
        );
        require(
            IERC721(nftContract).getApproved(tokenId) == address(this),
            "Marketplace must be approved"
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        _listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            listed: true
        });

        emit ItemListed(nftContract, tokenId, msg.sender, price);
    }

    function buyItem(address nftContract, uint256 tokenId) public payable {
        Listing storage listing = _listings[nftContract][tokenId];

        require(listing.listed, "Item is not listed");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Seller cannot buy their own listing");

        address seller = listing.seller;
        uint256 price = listing.price;

        listing.listed = false;
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        payable(seller).transfer(price);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit ItemSold(nftContract, tokenId, seller, msg.sender, price);
    }

    function cancelListing(address nftContract, uint256 tokenId) public {
        Listing storage listing = _listings[nftContract][tokenId];

        require(listing.listed, "Item is not listed");
        require(listing.seller == msg.sender, "You are not the seller");

        listing.listed = false;

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        emit ListingCancelled(nftContract, tokenId, msg.sender);
    }

    function getListing(
        address nftContract,
        uint256 tokenId
    ) public view returns (address seller, uint256 price, bool listed) {
        Listing storage listing = _listings[nftContract][tokenId];
        return (listing.seller, listing.price, listing.listed);
    }
}
