// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OnlyFans {
    uint public nextPlanId;

    struct Plan {
        address contentCreator;
        address token;
        uint256 subscriptionAmount;
        uint256 subscriptionFrequency;
    }

    struct Subscription {
        address subscriber;
        uint256 startSubscription;
        uint256 nextPayment;
    }

    mapping(uint256 => Plan) public plans;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;

    event PlanCreated(
        address contentCreator,
        uint256 planId,
        uint256 date
    );

    event SubscriptionCreated(
        address subscriber,
        uint256 planId,
        uint256 date
    );

    event SubscriptionCancelled(
        address subscriber,
        uint256 planId,
        uint256 date
    );

    event PaymentSent(
        address from,
        address to,
        uint256 subscriptionAmount,
        uint256 planId,
        uint256 date
    );

    function createPlan(address token, uint256 subscriptionAmount, uint256 subscriptionFrequency) external {
        require(token != address(0), "Address cannot be empty.");
        require(subscriptionAmount > 0, "Subscription amount needs to be greater than zero.");
        require(subscriptionFrequency > 0, "Subscription frequency needs to be greater than zero.");
        plans[nextPlanId] = Plan(
            msg.sender,
            token,
            subscriptionAmount,
            subscriptionFrequency
        );
        nextPlanId++;
    }

    function subscribe(uint256 planId) external {
        IERC20 token = IERC20(plans[planId].token);
        Plan storage plan = plans[planId];
        require(plan.contentCreator != address(0), "This plan does not exist.");

        token.transferFrom(msg.sender, plan.contentCreator, plan.subscriptionAmount);
        emit PaymentSent(
            msg.sender,
            plan.contentCreator,
            plan.subscriptionAmount,
            planId,
            block.timestamp
        );

        subscriptions[msg.sender][planId] = Subscription(
            msg.sender,
            block.timestamp,
            block.timestamp + plan.subscriptionFrequency
        );
        emit SubscriptionCreated(msg.sender, planId, block.timestamp);
    }

    function cancelSubscription(uint256 planId) external {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        require(
            subscription.subscriber != address(0),
            "This subscription does not exist."
        );
        delete subscriptions[msg.sender][planId];
        emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
    }

    function makePayment(address subscriber, uint256 planId) external payable {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        Plan storage plan = plans[planId];
        IERC20 token = IERC20(plan.token);
        require(
            subscription.subscriber != address(0),
            "This subscribe does not exist."
        );
        require(
            block.timestamp > subscription.nextPayment,
            "Next subscription payment is not due."
        );
        
        token.transferFrom(subscriber, plan.contentCreator, plan.subscriptionAmount);
        emit PaymentSent(
            subscriber,
            plan.contentCreator,
            plan.subscriptionAmount,
            planId,
            block.timestamp
        );
        subscription.nextPayment = subscription.nextPayment + plan.subscriptionFrequency;
    }
}