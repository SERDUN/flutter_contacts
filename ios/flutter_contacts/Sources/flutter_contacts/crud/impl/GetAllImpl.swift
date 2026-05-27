import Contacts
import Flutter

enum GetAllImpl {
    // Android mimetypes that iOS can approximate via CNContact field presence.
    // - phone_v2: has at least one phoneNumber
    // - email_v2: has at least one emailAddress
    // Unknown mimetypes do not constrain the result.
    private static let phoneMimetype = "vnd.android.cursor.item/phone_v2"
    private static let emailMimetype = "vnd.android.cursor.item/email_v2"

    static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let properties = Set(call.argList("properties") as [String]? ?? [])
        let enableIosNotes = call.arg("enableIosNotes", default: false)
        let filter: Json? = call.arg("filter")
        let accountJson: Json? = call.arg("account")
        let account = accountJson.map(Account.fromJson)
        let limit: Int? = call.arg("limit")
        let requiredDataMimetypes = Set(call.argList("requiredDataMimetypes") as [String]? ?? [])
        let requirePhone = requiredDataMimetypes.contains(phoneMimetype)
        let requireEmail = requiredDataMimetypes.contains(emailMimetype)
        let store = ContactStoreProvider.shared
        let containerId = AccountUtils.findContainer(account: account, store: store)?.identifier
        let predicate = PredicateBuilder.build(filter: filter, containerId: containerId)
        let keys = KeysBuilder.build(
            properties: properties,
            enableIosNotes: enableIosNotes,
            requirePhone: requirePhone,
            requireEmail: requireEmail
        )

        DispatchQueue.global(qos: .userInitiated).async {
            HandlerHelpers.handleResult(result) {
                let request = CNContactFetchRequest(keysToFetch: keys)
                request.predicate = predicate
                request.sortOrder = .givenName
                let options = ContactConverter.makeOptions(properties: properties, enableIosNotes: enableIosNotes)
                var contacts: [Json] = []
                if let limit = limit { contacts.reserveCapacity(limit) }
                try store.enumerateContacts(with: request) { contact, stop in
                    autoreleasepool {
                        if requirePhone, contact.phoneNumbers.isEmpty { return }
                        if requireEmail, contact.emailAddresses.isEmpty { return }
                        contacts.append(ContactConverter.toJson(contact, options: options))
                    }
                    if let limit = limit, contacts.count >= limit {
                        stop.pointee = true
                    }
                }
                return contacts
            }
        }
    }
}
