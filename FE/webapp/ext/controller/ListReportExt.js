sap.ui.define([
    "sap/m/MessageToast",
    "sap/m/MessageBox",
    "sap/ui/core/Element"
], function(MessageToast, MessageBox, Element) {
    "use strict";

    window._hasGetFilter = window._hasGetFilter || false;

    return {
        onGetFilter: function(oEvent) {
            var oFilterBar;
            var sFilterBarId = "fasttrack.fasttrack::BookingSrvList--fe::FilterBar::BookingSrv";
            
            if (Element && Element.registry) {
                oFilterBar = Element.registry.get(sFilterBarId);
            }
            if (!oFilterBar && sap.ui.getCore) {
                oFilterBar = sap.ui.getCore().byId(sFilterBarId);
            }

            if (!oFilterBar) {
                MessageToast.show("Lỗi: Không tìm thấy Filter Bar!");
                return;
            }

            var oConditions = oFilterBar.getConditions();
            console.log("JSON Dữ liệu bốc được từ FilterBar: ", oConditions);

            var sCustomerId  = oConditions.CustomerId ? oConditions.CustomerId[0].values[0] : "";
            var sCity        = oConditions.CustomerCity ? oConditions.CustomerCity[0].values[0] : "";
            var sPriority    = oConditions.Priority ? oConditions.Priority[0].values[0] : "";
            var sConfirmFlag = oConditions.ConfirmFlag ? oConditions.ConfirmFlag[0].values[0] : "";
            
            // --- GOM TOÀN BỘ NHIỀU GIÁ TRỊ STATUS (QUÉT TẤT CẢ CÁC ĐIỀU KIỆN) ---
            var sStatus = "";
            var aStatusCond = oConditions.OverallStatus || oConditions.Status;
            if (aStatusCond && Array.isArray(aStatusCond)) {
                var aAllStatusVals = [];
                aStatusCond.forEach(function(oCond) {
                    if (oCond.values && Array.isArray(oCond.values)) {
                        oCond.values.forEach(function(val) {
                            if (val) {
                                aAllStatusVals.push(val);
                            }
                        });
                    }
                });
                sStatus = aAllStatusVals.join(","); // Gom tất cả lại thành "N,A,X..."
            }

            // --- XỬ LÝ BOOKING DATE (Hỗ trợ chuẩn cả 1 ngày, Range Date và Operator "BT") ---
            var sBookingDateL = null;
            var sBookingDateH = null;

            if (oConditions.BookingDate && oConditions.BookingDate[0]) {
                var oDateCond = oConditions.BookingDate[0];
                var aVals = oDateCond.values;
                var sOp = oDateCond.operator;

                if (aVals && aVals.length > 0) {
                    if (sOp === "BT" || sOp === "DATERANGE") {
                        sBookingDateL = aVals[0] ? aVals[0].toString().substring(0, 10) : null;
                        sBookingDateH = aVals[1] ? aVals[1].toString().substring(0, 10) : sBookingDateL;
                    } else {
                        sBookingDateL = aVals[0] ? aVals[0].toString().substring(0, 10) : null;
                        sBookingDateH = sBookingDateL;
                    }
                }
            }

            var oModel = oFilterBar.getModel();
            if (!oModel) {
                MessageToast.show("Lỗi: Không tìm thấy OData Model!");
                return;
            }
            
            var sActionPath = "/BookingSrv/com.sap.gateway.srvd.zsv_booking_t35.v0001.GetFilter(...)";
            var oAction = oModel.bindContext(sActionPath);
            
            oAction.setParameter("customer_id", sCustomerId);
            oAction.setParameter("city", sCity);
            oAction.setParameter("status", sStatus);
            oAction.setParameter("priority", sPriority);
            oAction.setParameter("confirm_flag", sConfirmFlag); 
            oAction.setParameter("booking_date_l", sBookingDateL);
            oAction.setParameter("booking_date_h", sBookingDateH);

            sap.ui.core.BusyIndicator.show(0);
            
            oAction.execute().then(function() {
                sap.ui.core.BusyIndicator.hide();
                window._hasGetFilter = true; 
                MessageToast.show("Tuyệt vời! Đã lưu điều kiện lọc thành công!");
            }).catch(function(oError) {
                sap.ui.core.BusyIndicator.hide();
                MessageToast.show("Đã xảy ra lỗi OData, hãy kiểm tra Console.");
                console.error("Chi tiết lỗi OData:", oError);
            });
        },

        onProcess: function(oEvent) {
            if (!window._hasGetFilter) {
                MessageBox.error("Bạn phải nhấn nút 'Get Filter' trước khi Process!");
                return;
            }
        }
    };
});