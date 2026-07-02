# Security Client Rejection Runtime

Client rejections are categories, not punishments.

This runtime can define future categories for server rejection reasons. It does not reject live player actions, punish players, ban, kick, moderate, monitor, or enforce.

Client rejection schemas require `clientRejectionId`, `ownerSystem`, optional `schemaType = SecurityClientRejectionSchema`, safe metadata, safe context, and safe tags.

Client rejection categories cannot punish, moderate, ban, kick, or enforce. They are vocabulary for future server rejection reasons only, and duplicate or unsafe records reject before mutation.
