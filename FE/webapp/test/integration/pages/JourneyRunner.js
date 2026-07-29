sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"fasttrack/booking/test/integration/pages/BookingSrvList.gen",
	"fasttrack/booking/test/integration/pages/BookingSrvObjectPage.gen",
	"fasttrack/booking/test/integration/pages/BookingItemSrvObjectPage.gen"
], function (JourneyRunner, BookingSrvListGenerated, BookingSrvObjectPageGenerated, BookingItemSrvObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('fasttrack/booking') + '/test/flp.html#app-preview',
        pages: {
			onTheBookingSrvListGenerated: BookingSrvListGenerated,
			onTheBookingSrvObjectPageGenerated: BookingSrvObjectPageGenerated,
			onTheBookingItemSrvObjectPageGenerated: BookingItemSrvObjectPageGenerated
        },
        async: true
    });

    return runner;
});

