// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::royalty_rule {

    use sui::coin;
    use sui::sui;
    use sui::transfer_policy;

    /// The `amount_bp` passed is more than 100%.
    const EIncorrectArgument: u64 = 0;
    /// The `Coin` used for payment is not enough to cover the fee.
    const EInsufficientAmount: u64 = 1;

    /// The Rule Witness to authorize the policy
    public struct Rule has drop {}

    /// Configuration for the Rule
    public struct Config has store, drop {
        /// Basis points of the transfer amount to be paid as royalty fee
        amount_bp: u16,
    }

    /// Function that adds a Rule to the `TransferPolicy`.
    /// Requires `TransferPolicyCap` to make sure the rules are
    /// added only by the publisher of T.
    public fun add<T>(
        policy: &mut transfer_policy::TransferPolicy<T>,
        cap: &transfer_policy::TransferPolicyCap<T>,
        amount_bp: u16,

    ) {
        assert!(amount_bp <= 10_000, EIncorrectArgument);        
        transfer_policy::add_rule(Rule {}, policy, cap, Config { amount_bp })
    }

    public fun fee_amount<T: key + store>(policy: &transfer_policy::TransferPolicy<T>, paid: u64): u64 {
        let config: &Config = transfer_policy::get_rule(Rule {}, policy);
        let amount_bp = (paid as u128) * (config.amount_bp as u128);
        // take ceil of amount_bp / 10_000,
        // note that ceil(a/b) in integer arithmetic is (a+b-1)/b
        let amount = ((amount_bp + 9_999) / 10_000) as u64;
        amount
    }

    /// Buyer action: Pay the royalty fee for the transfer.
    public fun pay<T: key + store>(
        policy: &mut transfer_policy::TransferPolicy<T>,
        request: &mut transfer_policy::TransferRequest<T>,
        payment: coin::Coin<sui::SUI>,
    ) {
        let paid = transfer_policy::paid(request);
        let amount = fee_amount(policy, paid);
        assert!(coin::value(&payment) >= amount, EInsufficientAmount);
        transfer_policy::add_to_balance(Rule {}, policy, payment);
        transfer_policy::add_receipt(Rule {}, request)
    }

}
