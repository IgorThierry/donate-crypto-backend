// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Campaign {
    address author;
    string title;
    string description;
    string videoUrl;
    string imageUrl;
    uint256 balance;
    bool active;
}

contract DonateCrypto {
    uint256 public donateFee = 100; //taxa fixa por campanha - 100 wei
    uint256 public nextId = 0;
    uint256 public feesBalance = 0;

    mapping(uint256 => Campaign) public campaigns; // id => campanha

    function addCampaign(
        string calldata title,
        string calldata description,
        string calldata videoUrl,
        string calldata imageUrl
    ) public {
        Campaign memory newCampaign;
        newCampaign.title = title;
        newCampaign.description = description;
        newCampaign.videoUrl = videoUrl;
        newCampaign.imageUrl = imageUrl;
        newCampaign.active = true;
        newCampaign.author = msg.sender;

        nextId++;
        campaigns[nextId] = newCampaign;
    }

    function donate(uint256 id) public payable {
        require(msg.value > 0, "You must send a donation value > 0");
        require(campaigns[id].active == true, "Cannot donate to this campaign");

        campaigns[id].balance += msg.value;
    }

    function withdraw(uint256 campaignId) public {
        Campaign memory campaign = campaigns[campaignId];
        require(campaign.author == msg.sender, "You do not have permission");
        require(campaign.active == true, "The campaign is closed");
        require(campaign.balance > donateFee, "This campaign does not have enough balance");

        address payable recipient = payable(campaign.author);

        uint256 amountToWithdraw = campaign.balance - donateFee;

        (bool success, ) = recipient.call{value: amountToWithdraw}("");
        require(success == true, "Failed to withdraw");

        feesBalance += donateFee;

        campaigns[campaignId].active = false;
        campaigns[campaignId].balance = 0;
    }
}
