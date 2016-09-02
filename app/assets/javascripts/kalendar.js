var dmn = "",
    api = "";
(function(e, t, n, r) {
    function o(t, n) {
        n = {
            A: n.startMonth,
            B: n.startYear,
            C: n.firstDayOfWeek,
            D: n.events,
            E: n.color,
            F: n.showDays,
            G: n.tracking,
            H: n.template,
            I: {
                A: n.monthShow,
                B: n.prevMonth,
                C: n.nextMonth,
                D: n.grid,
                E: n.specday_trigger,
                F: n.specday_day,
                G: n.specday_date,
                H: n.specday_scheme
            },
            J: n.monthHuman,
            K: n.dayHuman,
            L: n.dayMachine,
            M: n.urlText,
            N: n.onInitiated,
            O: n.onGoogleParsed,
            P: n.onMonthChanged,
            Q: n.onDayShow,
            R: n.onGridShow,
            S: n.onDayClick,
            T: n.eventsParsed,
            U: n.googleCal,
            V: n.eventColors
        };
        this.A = e.extend(true, {}, s, n);
        this.B = t;
        this.C = this.A.A;
        this.D = this.A.B;
        this.E = new Date(this.D, this.C);
        this.K = [this.A.L(this.A.C), this.A.C];
        this.F = new Date;
        this.F.setHours(0, 0, 0, 0);
        this.Q()
    }

    function u(e, t) {
        if (t == "YYYYMMDD") {
            e = e.toString();
            d = new Date;
            d.setYear(e.substring(0, 4));
            d.setMonth(e.substring(4, 6) - 1);
            d.setDate(e.substring(6, 8))
        } else if (t == "YYYYMMDDHHMM") {
            d = new Date;
            st = e[0].toString();
            d.setYear(st.substring(0, 4));
            d.setMonth(st.substring(4, 6) - 1);
            d.setDate(st.substring(6, 8));
            st = e[1].toString();
            st = st.split(".")[0].length < 2 ? "0" + st : st;
            d.setHours(st.substring(0, 2));
            d.setMinutes(st.substring(3, 5));
            d.setSeconds(0)
        }
        return d
    }

    function a(e, t) {
        var n = function(e) {
            return e < 10 ? 0 + "" + e : e
        };
        if (t == "YYYYMMDD") {
            var r = e.getFullYear(),
                i = n(e.getMonth() + 1),
                s = n(e.getDate());
            return r + "" + i + "" + s
        } else if (t == "HH.MM") {
            var o = n(e.getHours() + 1),
                u = n(e.getMinutes() + 1);
            return o + "." + u
        }
    }

    function f(t, n) {
        var r = function(e, t, n) {
            var n = !!n ? n : t.start.date;
            var r = {
                A: t.title,
                B: t.url,
                C: {
                    A: t.start.date,
                    B: t.start.time,
                    C: t.start.d
                },
                D: {
                    A: t.end.date,
                    B: t.end.time,
                    C: t.end.d
                },
                E: t.location,
                F: t.allDay,
                G: t.color
            };
            if (!e[n]) {
                e[n] = []
            }
            e[n].push(r)
        };
        n.start.date = parseInt(n.start.date);
        n.end.date = parseInt(n.end.date);
        if (n.start.date > n.end.date) {
            console.warn("The party was over before it started. That’s just an expression.", n)
        } else if (typeof n.start.date !== "number" || typeof n.end.date !== "number" || isNaN(n.end.date) || isNaN(n.start.date)) {
            console.warn("There is something wrong with this event, so it was skipped. Take a look at it", n)
        } else {
            if (n.start.date == n.end.date) {
                r(t, n)
            } else {
                var i = u(n.start.date, "YYYYMMDD"),
                    s = u(n.end.date, "YYYYMMDD"),
                    o = (s.getTime() - i.getTime()) / 864e5;
                for (var f = 0; f <= o; f++) {
                    var l = e.extend(true, {}, n),
                        c = new Date(i.getTime() + 864e5 * f),
                        h = a(c, "YYYYMMDD");
                    if (f == 0) {
                        r(t, l, h)
                    } else if (f == o) {
                        r(t, l, h)
                    } else {
                        l.allDay = true;
                        r(t, l, h)
                    }
                }
            }
        }
        return t
    }
    var i = n.domain;
    e.fn.kalendar = function(t) {
        t = typeof t == "undefined" ? {} : t;
        return this.each(function() {
            if (t.events !== r) {
                t.eventsParsed = [];
                for (var n = 0; n < t.events.length; n++) {
                    var i = t.events[n];
                    i.end.date = i.end.date == r ? i.start.date : i.end.date;
                    i.start.d = u([i.start.date, i.start.time], "YYYYMMDDHHMM");
                    i.end.d = u([i.end.date, i.end.time], "YYYYMMDDHHMM");
                    t.eventsParsed = f(t.eventsParsed, i)
                }
            }
            var s = new o(e(this), t);
            e(this).data("kalendar-instance", s)
        })
    };
    var s = {
        A: (new Date).getMonth(),
        B: (new Date).getFullYear(),
        C: "Monday",
        D: [],
        E: "red",
        F: true,
        G: true,
        H: '<div class="c-month-view"><div class="c-month-arrow-left">‹</div><p></p><div class="c-month-arrow-right">›</div></div><div class="c-holder"><div class="c-grid"></div><div class="c-specific"><div class="specific-day"><div class="specific-day-info" i="date"></div><div class="specific-day-info" i="day"></div></div><div class="s-scheme"></div></div></div>',
        I: {
            A: ".c-month-view p",
            B: ".c-month-arrow-left",
            C: ".c-month-arrow-right",
            D: ".c-grid",
            E: ".specific-day",
            F: ".specific-day-info[i=day]",
            G: ".specific-day-info[i=date]",
            H: ".s-scheme"
        },
        J: [
            ["JAN", "January"],
            ["FEB", "February"],
            ["MAR", "March"],
            ["APR", "April"],
            ["MAY", "May"],
            ["JUN", "June"],
            ["JUL", "July"],
            ["AUG", "August"],
            ["SEP", "September"],
            ["OCT", "October"],
            ["NOV", "November"],
            ["DEC", "December"]
        ],
        K: [
            ["S", "Sunday"],
            ["M", "Monday"],
            ["T", "Thursday"],
            ["W", "Wednesday"],
            ["T", "Thursday"],
            ["F", "Friday"],
            ["S", "Saturday"]
        ],
        L: function(e) {
            var t = [];
            t["Sunday"] = 0;
            t["Monday"] = 1;
            t["Tuesday"] = 2;
            t["Wednesday"] = 3;
            t["Thursday"] = 4;
            t["Friday"] = 5;
            t["Saturday"] = 6;
            return t[e]
        },
        M: "View on Web",
        N: function() {},
        O: function() {},
        P: function() {},
        Q: function() {},
        R: function() {},
        S: function(e) {},
        T: []
    };
    o.prototype.Q = function() {
        if (dmn == "") {
            console.warn("This is an invalid API-key (" + api + ")")
        } else if (dmn !== "" && dmn !== i) {
            console.warn("This domain (" + i + ") is not accepted for this API-key (" + api + "). The accepted domain is " + dmn)
        }
        if (dmn == i) {
            this.H()
        } else {
            $A = e('<img src="">');
            this.G = $A;
            this.B.append(this.G);
            var n = {
                url: t.location.href,
                domain: i,
                api: api,
                accdomain: dmn,
                color: this.A.E,
                showdays: this.A.F,
                firstdayofweek: this.A.C,
                width: this.B.outerWidth(),
                height: this.B.outerHeight(),
                windowwidth: t.innerWidth,
                windowheight: t.innerHeight
            };
            var r = "http://www.ericwenn.se/php/trackingkalendar.php";
            var s = 0;
            e.each(n, function(e, t) {
                r += (s == 0 ? "?" : "&") + e + "=" + encodeURIComponent(t);
                s++
            });
            this.G.attr("src", r);
            this.H()
        }
    };
    o.prototype.H = function() {
        var t = function(t, r) {
            e.ajax({
                url: "https://www.googleapis.com/calendar/v3/calendars/" + t + "/events?key=" + r,
                dataType: "json",
                async: false,
                success: function(e) {
                    for (var t = 0; t < e.items.length; t++) {
                        var r = e.items[t];
                        if (typeof r.start !== "undefined" && typeof r.end !== "undefined" && typeof r.start.dateTime !== "undefined" && typeof r.end.dateTime !== "undefined") {
                            var i = new Date(r.start.dateTime),
                                s = new Date(r.end.dateTime),
                                o = {
                                    title: r.summary,
                                    location: r.location,
                                    start: {
                                        date: a(i, "YYYYMMDD"),
                                        time: a(i, "HH.MM"),
                                        d: new Date(r.start.dateTime)
                                    },
                                    end: {
                                        date: a(s, "YYYYMMDD"),
                                        time: a(s, "HH.MM"),
                                        d: new Date(r.end.dateTime)
                                    }
                                };
                            n = f(n, o)
                        }
                    }
                }
            })
        };
        var n = this.A.T;
        if (!!this.A.U) {
            if (this.A.U instanceof Array) {
                for (var r = 0; r < this.A.U.length; r++) {
                    t(this.A.U[r].calendar, this.A.U[r].apikey)
                }
            } else {
                t(this.A.U.calendar, this.A.U.apikey)
            }
        }
        this.A.T = n;
        this.L();
        !!this.A.U ? this.A.O() : null
    };
    o.prototype.L = function() {
        this.B.html(this.A.H);
        this.B.attr("kalendar", "");
        this.B.attr("color", this.A.E);
        this.J = {};
        for (var e in this.A.I) {
            this.J[e] = this.B.find(this.A.I[e])
        }
        if (!this.A.F) {
            this.B.attr("showdays", false)
        }
        if ("ontouchstart" in n.documentElement) {
            this.B.attr("touch-enabled", true)
        }
        if (this.B.outerWidth() < 400) {
            this.B.addClass("small")
        }
        this.R = function(e) {
            var t = ["th", "st", "nd", "rd"],
                n = e % 100;
            return e + (t[(n - 20) % 10] || t[n] || t[0])
        };
        this.M();
        this.J.B.on("click", {
            self: this,
            dir: "prev"
        }, this.N);
        this.J.C.on("click", {
            self: this,
            dir: "next"
        }, this.N);
        this.A.N()
    };
    o.prototype.N = function(e) {
        var t = e.data.self;
        var n = e.data.dir;
        t.C += n == "prev" ? -1 : 1;
        t.E = new Date(t.D, t.C);
        t.C = t.E.getMonth();
        t.D = t.E.getFullYear();
        t.M()
    };
    o.prototype.M = function() {
        var t = this.J.D;
        t.html("");
        this.J.A.html(this.A.J[this.E.getMonth()][1] + " " + this.E.getFullYear());
        if (this.A.F) {
            $dayView = e('<div class="c-row"></div>');
            for (var n = 0; n < 7; n++) {
                var i = this.K[0] + n;
                i -= i > 6 ? 7 : 0;
                $dayView.append('<div class="c-day c-l"><div class="date-holder">' + this.A.K[i][0] + "</div></div>")
            }
            t.append($dayView)
        }
        var s = new Date(this.E),
            o = s.getDay() - this.K[0],
            u = {};
        o += o < 1 ? 7 : 0;
        s.setDate(s.getDate() - o);
        for (var n = 0; n < 42; n++) {
            if (n == 0 || n % 7 == 0) {
                $row = e('<div class="c-row"></div>');
                t.append($row)
            }
            $day = e('<div class="c-day"><div class="date-holder">' + s.getDate() + "</div></div>");
            u[n] = new Date(s);
            if (s.getMonth() !== this.E.getMonth()) {
                $day.addClass("other-month");
                $day.on("click", {
                    info: "other-month",
                    date: u[n]
                }, this.A.S)
            } else if (s.getTime() == this.F.getTime()) {
                $day.addClass("this-day");
                $day.on("click", {
                    info: "this-day",
                    date: u[n]
                }, this.A.S)
            } else {
                $day.on("click", {
                    info: "this-month",
                    date: u[n]
                }, this.A.S)
            }
            var f = a(s, "YYYYMMDD");
            if (this.A.T[f] !== r) {
                $day.addClass("have-events");
                $eventholder = e('<div class="event-n-holder"></div>');
                for (var l = 0; l < 3 && l < this.A.T[f].length; l++) {
                    $eventholder.append('<div class="event-n"></div>')
                }
                $day.on("click", {
                    day: this.A.T[f],
                    self: this,
                    date: s.getTime(),
                    strtime: f
                }, this.O);
                $day.append($eventholder)
            }
            $row.append($day);
            s.setDate(s.getDate() + 1)
        }
        this.A.P(this.E)
    };
    o.prototype.O = function(t) {
        var n = t.data.day,
            r = t.data.self,
            i = new Date(t.data.date),
            s = t.data.strtime;
        r.B.addClass("spec-day");
        r.J.F.html(r.A.K[i.getDay()][1]);
        r.J.G.html(i.getDate());
        r.J.E.on("click", {
            self: r
        }, r.P);
        for (var o = 0; o < n.length; o++) {
            ev = n[o];
            var u = "",
                a = "",
                f = "",
                l = "";
            if (!!ev.G) {
                var c = r.A.V[ev.G];
                if (!!c) {
                    u = !!c.text ? 'style="color:' + c.text + '"' : "";
                    a = !!c.text ? 'style="color:' + c.text + ';opacity:0.5"' : "";
                    f = !!c.link ? 'style="color:' + c.link + '"' : "";
                    l = !!c.background ? 'style="background-color:' + c.background + '"' : ""
                }
            }
            $event = e('<div class="s-event" ' + l + "></div>");
            $event.append("<h5 " + u + ">" + ev.A + "</h5>");
            var h = {
                    date: ev.C.C.getDate() == ev.D.C.getDate() ? "" : r.R(ev.C.C.getDate()),
                    month: ev.C.C.getMonth() == ev.D.C.getMonth() ? "" : r.A.J[ev.C.C.getMonth()][1],
                    year: ev.C.C.getFullYear() == ev.D.C.getFullYear() ? "" : ev.C.C.getFullYear()
                },
                p = {
                    date: ev.C.C.getDate() == ev.D.C.getDate() ? "" : r.R(ev.D.C.getDate()),
                    month: ev.C.C.getMonth() == ev.D.C.getMonth() ? "" : r.A.J[ev.D.C.getMonth()][1],
                    year: ev.C.C.getFullYear() == ev.D.C.getFullYear() ? "" : ev.D.C.getFullYear()
                };
            var h = h.date + " " + h.month + " " + h.year + " " + ev.C.B,
                p = p.date + " " + p.month + " " + p.year + " " + ev.D.B;
            $event.append("<p " + a + ">" + h + " - " + p + "</p>");
            !!ev.E ? $event.append("<p " + a + ">" + ev.E + "</p>") : null;
            !!ev.url ? $event.append("<p><a " + f + ' href="' + ev.B + '">' + r.options.urlText + "</a></p>") : null;
            r.J.H.append($event)
        }
        r.A.Q
    };
    o.prototype.P = function(e) {
        var t = e.data.self;
        t.B.removeClass("spec-day");
        t.J.H.html("");
        t.A.R()
    }
})(jQuery, window, document);
var style = document.createElement("style");
var text = "[kalendar]{color:white;font-weight:300;height:20em;line-height:1.5}[kalendar] *{box-sizing:border-box;moz-box-sizing:border-box;vertical-align:top}[kalendar].small .c-month-view{font-size:1.3em;line-height:2}[kalendar].small .c-holder{font-size:0.8em;font-weight:100}[kalendar] .c-month-view{-webkit-transition:all 0.5s;-moz-transition:all 0.5s;transition:all 0.5s;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;-o-user-select:none;user-select:none;height:12.5%;position:relative;font-size:1.5em;line-height:1.5;margin-bottom:1px;text-align:center}[kalendar] .c-month-view [class^=c-month-arrow]{width:15%;height:100%;position:absolute;top:0;color:transparent;cursor:pointer}[kalendar] .c-month-view [class^=c-month-arrow]:hover{background:rgba(255,255,255,0.25)}[kalendar] .c-month-view .c-month-arrow-left{left:0}[kalendar] .c-month-view .c-month-arrow-right{right:0}[kalendar] .c-month-view p{margin:0 !important;font-size:0.9em}[kalendar] .c-holder{height:87.5%;position:relative}[kalendar] .c-grid{position:absolute;height:100%;width:100%;top:0;left:0}[kalendar] .c-grid .c-row{width:100%;margin-bottom:0.2%;margin-bottom:-moz-calc(0px + 1px);margin-bottom:-o-calc(0px + 1px);margin-bottom:-webkit-calc(0px + 1px);margin-bottom:calc(0px + 1px);height:13.1%;height:-moz-calc(100%/7 - 7px/6);height:-o-calc(100%/7 - 7px/6);height:-webkit-calc(100%/7 - 7px/6);height:calc(100%/7 - 7px/6)}[kalendar] .c-grid .c-row:last-child{margin-bottom:0}[kalendar] .c-grid .c-row .c-day{margin-right:0.2%;margin-right:-moz-calc(0px + 7px/6);margin-right:-o-calc(0px + 7px/6);margin-right:-webkit-calc(0px + 7px/6);margin-right:calc(0px + 7px/6);width:14.1%;width:-moz-calc(99.9%/7 - 1px);width:-o-calc(99.9%/7 - 1px);width:-webkit-calc(99.9%/7 - 1px);width:calc(99.9%/7 - 1px);height:100%;display:inline-block;position:relative}[kalendar] .c-grid .c-row .c-day.c-l .date-holder{font-size:1em}[kalendar] .c-grid .c-row .c-day:last-child{margin-right:0}[kalendar] .c-grid .c-row .c-day.have-events{cursor:pointer}[kalendar] .c-grid .c-row .c-day.have-events:hover{background-color:#232323}[kalendar] .c-grid .c-row .c-day.other-month{color:#373737}[kalendar] .c-grid .c-row .c-day.other-month.have-events:hover{color:white}[kalendar] .c-grid .c-row .c-day.this-day{background:none}[kalendar] .c-grid .c-row .c-day .date-holder{font-size:1.3em;position:absolute;right:5%;bottom:5%}[kalendar] .c-grid .c-row .c-day .event-n-holder{height:90%;height:-moz-calc(100% - 10px);height:-o-calc(100% - 10px);height:-webkit-calc(100% - 10px);height:calc(100% - 10px);left:5%;left:-moz-calc(0px + 5px);left:-o-calc(0px + 5px);left:-webkit-calc(0px + 5px);left:calc(0px + 5px);top:5%;top:-moz-calc(0px + 5px);top:-o-calc(0px + 5px);top:-webkit-calc(0px + 5px);top:calc(0px + 5px);position:absolute;width:0.25em}[kalendar] .c-grid .c-row .c-day .event-n-holder .event-n{height:0.5em;background-color:white;width:100%;margin:1px 0}[kalendar] .c-specific{position:absolute;width:100%;height:100%;left:0;top:0;display:none;padding:1px;padding-top:0px}[kalendar] .c-specific .specific-day{vertical-align:top;width:30%;display:inline-block;line-height:1;padding:1em 0;cursor:pointer;text-align:center}[kalendar] .c-specific .specific-day:hover{background:#232323}[kalendar] .c-specific .specific-day [i=date]{font-size:3em}[kalendar] .c-specific .specific-day [i=day]{font-size:1.5em}[kalendar] .c-specific .s-scheme{display:inline-block;height:100%;margin-left:1px;width:60%;width:-moz-calc(70% - 1px);width:-o-calc(70% - 1px);width:-webkit-calc(70% - 1px);width:calc(70% - 1px);overflow-y:auto;text-align:left;vertical-align:top}[kalendar] .c-specific .s-scheme::-webkit-scrollbar{width:10px}[kalendar] .c-specific .s-scheme::-webkit-scrollbar-track{background:transparent}[kalendar] .c-specific .s-scheme::-webkit-scrollbar-thumb{background:#232323}[kalendar] .c-specific .s-scheme .s-event{width:100%;padding:0.5em;margin:1px 0}[kalendar] .c-specific .s-scheme .s-event:first-child{margin-top:0}[kalendar] .c-specific .s-scheme .s-event:last-child{margin-bottom:0}[kalendar] .c-specific .s-scheme .s-event h5{margin:0;font-size:1.1em;line-height:1.3;font-weight:400;color:white}[kalendar] .c-specific .s-scheme .s-event p{margin:0;color:rgba(255,255,255,0.56);line-height:1.3}[kalendar] .c-specific .s-scheme .s-event a{font-weight:normal}[kalendar] .c-specific .s-scheme .s-event p[data-role=loc]{line-height:1}[kalendar]:hover .c-month-view{background:#232323 !important}[kalendar]:hover .c-month-view [class^=c-month-arrow]{color:white}[kalendar].spec-day .c-grid{display:none}[kalendar].spec-day .c-specific{display:block}[kalendar].spec-day [class^=c-month-arrow]{display:none}[kalendar][touch-enabled=true] .c-month-view [class^=c-month-arrow]{color:white}[kalendar][showdays=false] .c-holder .c-grid .c-row{height:15.67%;height:-moz-calc(100%/6 - 7px/6);height:-o-calc(100%/6 - 7px/6);height:-webkit-calc(100%/6 - 7px/6);height:calc(100%/6 - 7px/6)}[color=red]{background-color:#E83C2C}[color=red] .c-month-view,[color=red] .c-day,[color=red] .specific-day,[color=red] .s-event{background-color:#C1291B}[color=blue]{background-color:#2497DB}[color=blue] .c-month-view,[color=blue] .c-day,[color=blue] .specific-day,[color=blue] .s-event{background-color:#3081B9}[color=green]{background-color:#2ECC70}[color=green] .c-month-view,[color=green] .c-day,[color=green] .specific-day,[color=green] .s-event{background-color:#28AE61}[color=yellow]{background-color:#F2C30F}[color=yellow] .c-month-view,[color=yellow] .c-day,[color=yellow] .specific-day,[color=yellow] .s-event{background-color:#F39C12}";
style.setAttribute("type", "text/css");
if (style.styleSheet) {
    style.styleSheet.cssText = text
} else {
    var textnode = document.createTextNode(text);
    style.appendChild(textnode)
}
var h = document.getElementsByTagName("head")[0];
h.appendChild(style);
var dmn = "",
    api = "";
(function(e, t, n, r) {
    function o(t, n) {
        n = {
            A: n.startMonth,
            B: n.startYear,
            C: n.firstDayOfWeek,
            D: n.events,
            E: n.color,
            F: n.showDays,
            G: n.tracking,
            H: n.template,
            I: {
                A: n.monthShow,
                B: n.prevMonth,
                C: n.nextMonth,
                D: n.grid,
                E: n.specday_trigger,
                F: n.specday_day,
                G: n.specday_date,
                H: n.specday_scheme
            },
            J: n.monthHuman,
            K: n.dayHuman,
            L: n.dayMachine,
            M: n.urlText,
            N: n.onInitiated,
            O: n.onGoogleParsed,
            P: n.onMonthChanged,
            Q: n.onDayShow,
            R: n.onGridShow,
            S: n.onDayClick,
            T: n.eventsParsed,
            U: n.googleCal,
            V: n.eventColors
        };
        this.A = e.extend(true, {}, s, n);
        this.B = t;
        this.C = this.A.A;
        this.D = this.A.B;
        this.E = new Date(this.D, this.C);
        this.K = [this.A.L(this.A.C), this.A.C];
        this.F = new Date;
        this.F.setHours(0, 0, 0, 0);
        this.Q()
    }

    function u(e, t) {
        if (t == "YYYYMMDD") {
            e = e.toString();
            d = new Date;
            d.setYear(e.substring(0, 4));
            d.setMonth(e.substring(4, 6) - 1);
            d.setDate(e.substring(6, 8))
        } else if (t == "YYYYMMDDHHMM") {
            d = new Date;
            st = e[0].toString();
            d.setYear(st.substring(0, 4));
            d.setMonth(st.substring(4, 6) - 1);
            d.setDate(st.substring(6, 8));
            st = e[1].toString();
            st = st.split(".")[0].length < 2 ? "0" + st : st;
            d.setHours(st.substring(0, 2));
            d.setMinutes(st.substring(3, 5));
            d.setSeconds(0)
        }
        return d
    }

    function a(e, t) {
        var n = function(e) {
            return e < 10 ? 0 + "" + e : e
        };
        if (t == "YYYYMMDD") {
            var r = e.getFullYear(),
                i = n(e.getMonth() + 1),
                s = n(e.getDate());
            return r + "" + i + "" + s
        } else if (t == "HH.MM") {
            var o = n(e.getHours() + 1),
                u = n(e.getMinutes() + 1);
            return o + "." + u
        }
    }

    function f(t, n) {
        var r = function(e, t, n) {
            var n = !!n ? n : t.start.date;
            var r = {
                A: t.title,
                B: t.url,
                C: {
                    A: t.start.date,
                    B: t.start.time,
                    C: t.start.d
                },
                D: {
                    A: t.end.date,
                    B: t.end.time,
                    C: t.end.d
                },
                E: t.location,
                F: t.allDay,
                G: t.color
            };
            if (!e[n]) {
                e[n] = []
            }
            e[n].push(r)
        };
        n.start.date = parseInt(n.start.date);
        n.end.date = parseInt(n.end.date);
        if (n.start.date > n.end.date) {
            console.warn("The party was over before it started. That’s just an expression.", n)
        } else if (typeof n.start.date !== "number" || typeof n.end.date !== "number" || isNaN(n.end.date) || isNaN(n.start.date)) {
            console.warn("There is something wrong with this event, so it was skipped. Take a look at it", n)
        } else {
            if (n.start.date == n.end.date) {
                r(t, n)
            } else {
                var i = u(n.start.date, "YYYYMMDD"),
                    s = u(n.end.date, "YYYYMMDD"),
                    o = (s.getTime() - i.getTime()) / 864e5;
                for (var f = 0; f <= o; f++) {
                    var l = e.extend(true, {}, n),
                        c = new Date(i.getTime() + 864e5 * f),
                        h = a(c, "YYYYMMDD");
                    if (f == 0) {
                        r(t, l, h)
                    } else if (f == o) {
                        r(t, l, h)
                    } else {
                        l.allDay = true;
                        r(t, l, h)
                    }
                }
            }
        }
        return t
    }
    var i = n.domain;
    e.fn.kalendar = function(t) {
        t = typeof t == "undefined" ? {} : t;
        return this.each(function() {
            if (t.events !== r) {
                t.eventsParsed = [];
                for (var n = 0; n < t.events.length; n++) {
                    var i = t.events[n];
                    i.end.date = i.end.date == r ? i.start.date : i.end.date;
                    i.start.d = u([i.start.date, i.start.time], "YYYYMMDDHHMM");
                    i.end.d = u([i.end.date, i.end.time], "YYYYMMDDHHMM");
                    t.eventsParsed = f(t.eventsParsed, i)
                }
            }
            var s = new o(e(this), t);
            e(this).data("kalendar-instance", s)
        })
    };
    var s = {
        A: (new Date).getMonth(),
        B: (new Date).getFullYear(),
        C: "Monday",
        D: [],
        E: "red",
        F: true,
        G: true,
        H: '<div class="c-month-view"><div class="c-month-arrow-left">‹</div><p></p><div class="c-month-arrow-right">›</div></div><div class="c-holder"><div class="c-grid"></div><div class="c-specific"><div class="specific-day"><div class="specific-day-info" i="date"></div><div class="specific-day-info" i="day"></div></div><div class="s-scheme"></div></div></div>',
        I: {
            A: ".c-month-view p",
            B: ".c-month-arrow-left",
            C: ".c-month-arrow-right",
            D: ".c-grid",
            E: ".specific-day",
            F: ".specific-day-info[i=day]",
            G: ".specific-day-info[i=date]",
            H: ".s-scheme"
        },
        J: [
            ["JAN", "January"],
            ["FEB", "February"],
            ["MAR", "March"],
            ["APR", "April"],
            ["MAY", "May"],
            ["JUN", "June"],
            ["JUL", "July"],
            ["AUG", "August"],
            ["SEP", "September"],
            ["OCT", "October"],
            ["NOV", "November"],
            ["DEC", "December"]
        ],
        K: [
            ["S", "Sunday"],
            ["M", "Monday"],
            ["T", "Thursday"],
            ["W", "Wednesday"],
            ["T", "Thursday"],
            ["F", "Friday"],
            ["S", "Saturday"]
        ],
        L: function(e) {
            var t = [];
            t["Sunday"] = 0;
            t["Monday"] = 1;
            t["Tuesday"] = 2;
            t["Wednesday"] = 3;
            t["Thursday"] = 4;
            t["Friday"] = 5;
            t["Saturday"] = 6;
            return t[e]
        },
        M: "View on Web",
        N: function() {},
        O: function() {},
        P: function() {},
        Q: function() {},
        R: function() {},
        S: function(e) {},
        T: []
    };
    o.prototype.Q = function() {
        if (dmn == "") {
            console.warn("This is an invalid API-key (" + api + ")")
        } else if (dmn !== "" && dmn !== i) {
            console.warn("This domain (" + i + ") is not accepted for this API-key (" + api + "). The accepted domain is " + dmn)
        }
        if (dmn == i) {
            this.H()
        } else {
            $A = e('<img src="">');
            this.G = $A;
            this.B.append(this.G);
            var n = {
                url: t.location.href,
                domain: i,
                api: api,
                accdomain: dmn,
                color: this.A.E,
                showdays: this.A.F,
                firstdayofweek: this.A.C,
                width: this.B.outerWidth(),
                height: this.B.outerHeight(),
                windowwidth: t.innerWidth,
                windowheight: t.innerHeight
            };
            var r = "http://www.ericwenn.se/php/trackingkalendar.php";
            var s = 0;
            e.each(n, function(e, t) {
                r += (s == 0 ? "?" : "&") + e + "=" + encodeURIComponent(t);
                s++
            });
            this.G.attr("src", r);
            this.H()
        }
    };
    o.prototype.H = function() {
        var t = function(t, r) {
            e.ajax({
                url: "https://www.googleapis.com/calendar/v3/calendars/" + t + "/events?key=" + r,
                dataType: "json",
                async: false,
                success: function(e) {
                    for (var t = 0; t < e.items.length; t++) {
                        var r = e.items[t];
                        if (typeof r.start !== "undefined" && typeof r.end !== "undefined" && typeof r.start.dateTime !== "undefined" && typeof r.end.dateTime !== "undefined") {
                            var i = new Date(r.start.dateTime),
                                s = new Date(r.end.dateTime),
                                o = {
                                    title: r.summary,
                                    location: r.location,
                                    start: {
                                        date: a(i, "YYYYMMDD"),
                                        time: a(i, "HH.MM"),
                                        d: new Date(r.start.dateTime)
                                    },
                                    end: {
                                        date: a(s, "YYYYMMDD"),
                                        time: a(s, "HH.MM"),
                                        d: new Date(r.end.dateTime)
                                    }
                                };
                            n = f(n, o)
                        }
                    }
                }
            })
        };
        var n = this.A.T;
        if (!!this.A.U) {
            if (this.A.U instanceof Array) {
                for (var r = 0; r < this.A.U.length; r++) {
                    t(this.A.U[r].calendar, this.A.U[r].apikey)
                }
            } else {
                t(this.A.U.calendar, this.A.U.apikey)
            }
        }
        this.A.T = n;
        this.L();
        !!this.A.U ? this.A.O() : null
    };
    o.prototype.L = function() {
        this.B.html(this.A.H);
        this.B.attr("kalendar", "");
        this.B.attr("color", this.A.E);
        this.J = {};
        for (var e in this.A.I) {
            this.J[e] = this.B.find(this.A.I[e])
        }
        if (!this.A.F) {
            this.B.attr("showdays", false)
        }
        if ("ontouchstart" in n.documentElement) {
            this.B.attr("touch-enabled", true)
        }
        if (this.B.outerWidth() < 400) {
            this.B.addClass("small")
        }
        this.R = function(e) {
            var t = ["th", "st", "nd", "rd"],
                n = e % 100;
            return e + (t[(n - 20) % 10] || t[n] || t[0])
        };
        this.M();
        this.J.B.on("click", {
            self: this,
            dir: "prev"
        }, this.N);
        this.J.C.on("click", {
            self: this,
            dir: "next"
        }, this.N);
        this.A.N()
    };
    o.prototype.N = function(e) {
        var t = e.data.self;
        var n = e.data.dir;
        t.C += n == "prev" ? -1 : 1;
        t.E = new Date(t.D, t.C);
        t.C = t.E.getMonth();
        t.D = t.E.getFullYear();
        t.M()
    };
    o.prototype.M = function() {
        var t = this.J.D;
        t.html("");
        this.J.A.html(this.A.J[this.E.getMonth()][1] + " " + this.E.getFullYear());
        if (this.A.F) {
            $dayView = e('<div class="c-row"></div>');
            for (var n = 0; n < 7; n++) {
                var i = this.K[0] + n;
                i -= i > 6 ? 7 : 0;
                $dayView.append('<div class="c-day c-l"><div class="date-holder">' + this.A.K[i][0] + "</div></div>")
            }
            t.append($dayView)
        }
        var s = new Date(this.E),
            o = s.getDay() - this.K[0],
            u = {};
        o += o < 1 ? 7 : 0;
        s.setDate(s.getDate() - o);
        for (var n = 0; n < 42; n++) {
            if (n == 0 || n % 7 == 0) {
                $row = e('<div class="c-row"></div>');
                t.append($row)
            }
            $day = e('<div class="c-day"><div class="date-holder">' + s.getDate() + "</div></div>");
            u[n] = new Date(s);
            if (s.getMonth() !== this.E.getMonth()) {
                $day.addClass("other-month");
                $day.on("click", {
                    info: "other-month",
                    date: u[n]
                }, this.A.S)
            } else if (s.getTime() == this.F.getTime()) {
                $day.addClass("this-day");
                $day.on("click", {
                    info: "this-day",
                    date: u[n]
                }, this.A.S)
            } else {
                $day.on("click", {
                    info: "this-month",
                    date: u[n]
                }, this.A.S)
            }
            var f = a(s, "YYYYMMDD");
            if (this.A.T[f] !== r) {
                $day.addClass("have-events");
                $eventholder = e('<div class="event-n-holder"></div>');
                for (var l = 0; l < 3 && l < this.A.T[f].length; l++) {
                    $eventholder.append('<div class="event-n"></div>')
                }
                $day.on("click", {
                    day: this.A.T[f],
                    self: this,
                    date: s.getTime(),
                    strtime: f
                }, this.O);
                $day.append($eventholder)
            }
            $row.append($day);
            s.setDate(s.getDate() + 1)
        }
        this.A.P(this.E)
    };
    o.prototype.O = function(t) {
        var n = t.data.day,
            r = t.data.self,
            i = new Date(t.data.date),
            s = t.data.strtime;
        r.B.addClass("spec-day");
        r.J.F.html(r.A.K[i.getDay()][1]);
        r.J.G.html(i.getDate());
        r.J.E.on("click", {
            self: r
        }, r.P);
        for (var o = 0; o < n.length; o++) {
            ev = n[o];
            var u = "",
                a = "",
                f = "",
                l = "";
            if (!!ev.G) {
                // var c = r.A.V[ev.G];
                // if (!!c) {
                //     u = !!c.text ? 'style="color:' + c.text + '"' : "";
                //     a = !!c.text ? 'style="color:' + c.text + ';opacity:0.5"' : "";
                //     f = !!c.link ? 'style="color:' + c.link + '"' : "";
                //     l = !!c.background ? 'style="background-color:' + c.background + '"' : ""
                // }
            }
            $event = e('<div class="s-event" ' + l + "></div>");
            $event.append("<h5 " + u + ">" + ev.A + "</h5>");
            var h = {
                    date: ev.C.C.getDate() == ev.D.C.getDate() ? "" : r.R(ev.C.C.getDate()),
                    month: ev.C.C.getMonth() == ev.D.C.getMonth() ? "" : r.A.J[ev.C.C.getMonth()][1],
                    year: ev.C.C.getFullYear() == ev.D.C.getFullYear() ? "" : ev.C.C.getFullYear()
                },
                p = {
                    date: ev.C.C.getDate() == ev.D.C.getDate() ? "" : r.R(ev.D.C.getDate()),
                    month: ev.C.C.getMonth() == ev.D.C.getMonth() ? "" : r.A.J[ev.D.C.getMonth()][1],
                    year: ev.C.C.getFullYear() == ev.D.C.getFullYear() ? "" : ev.D.C.getFullYear()
                };
            var h = h.date + " " + h.month + " " + h.year + " " + ev.C.B,
                p = p.date + " " + p.month + " " + p.year + " " + ev.D.B;
            $event.append("<p " + a + ">" + h + " - " + p + "</p>");
            !!ev.E ? $event.append("<p " + a + ">" + ev.E + "</p>") : null;
            !!ev.url ? $event.append("<p><a " + f + ' href="' + ev.B + '">' + r.options.urlText + "</a></p>") : null;
            r.J.H.append($event)
        }
        r.A.Q
    };
    o.prototype.P = function(e) {
        var t = e.data.self;
        t.B.removeClass("spec-day");
        t.J.H.html("");
        t.A.R()
    }
})(jQuery, window, document);
var style = document.createElement("style");
var text = "[kalendar]{color:white;font-weight:300;height:20em;line-height:1.5}[kalendar] *{box-sizing:border-box;moz-box-sizing:border-box;vertical-align:top}[kalendar].small .c-month-view{font-size:1.3em;line-height:2}[kalendar].small .c-holder{font-size:0.8em;font-weight:100}[kalendar] .c-month-view{-webkit-transition:all 0.5s;-moz-transition:all 0.5s;transition:all 0.5s;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;-o-user-select:none;user-select:none;height:12.5%;position:relative;font-size:1.5em;line-height:1.5;margin-bottom:1px;text-align:center}[kalendar] .c-month-view [class^=c-month-arrow]{width:15%;height:100%;position:absolute;top:0;color:transparent;cursor:pointer}[kalendar] .c-month-view [class^=c-month-arrow]:hover{background:rgba(255,255,255,0.25)}[kalendar] .c-month-view .c-month-arrow-left{left:0}[kalendar] .c-month-view .c-month-arrow-right{right:0}[kalendar] .c-month-view p{margin:0 !important;font-size:0.9em}[kalendar] .c-holder{height:87.5%;position:relative}[kalendar] .c-grid{position:absolute;height:100%;width:100%;top:0;left:0}[kalendar] .c-grid .c-row{width:100%;margin-bottom:0.2%;margin-bottom:-moz-calc(0px + 1px);margin-bottom:-o-calc(0px + 1px);margin-bottom:-webkit-calc(0px + 1px);margin-bottom:calc(0px + 1px);height:13.1%;height:-moz-calc(100%/7 - 7px/6);height:-o-calc(100%/7 - 7px/6);height:-webkit-calc(100%/7 - 7px/6);height:calc(100%/7 - 7px/6)}[kalendar] .c-grid .c-row:last-child{margin-bottom:0}[kalendar] .c-grid .c-row .c-day{margin-right:0.2%;margin-right:-moz-calc(0px + 7px/6);margin-right:-o-calc(0px + 7px/6);margin-right:-webkit-calc(0px + 7px/6);margin-right:calc(0px + 7px/6);width:14.1%;width:-moz-calc(99.9%/7 - 1px);width:-o-calc(99.9%/7 - 1px);width:-webkit-calc(99.9%/7 - 1px);width:calc(99.9%/7 - 1px);height:100%;display:inline-block;position:relative}[kalendar] .c-grid .c-row .c-day.c-l .date-holder{font-size:1em}[kalendar] .c-grid .c-row .c-day:last-child{margin-right:0}[kalendar] .c-grid .c-row .c-day.have-events{cursor:pointer}[kalendar] .c-grid .c-row .c-day.have-events:hover{background-color:#232323}[kalendar] .c-grid .c-row .c-day.other-month{color:#373737}[kalendar] .c-grid .c-row .c-day.other-month.have-events:hover{color:white}[kalendar] .c-grid .c-row .c-day.this-day{background:none}[kalendar] .c-grid .c-row .c-day .date-holder{font-size:1.3em;position:absolute;right:5%;bottom:5%}[kalendar] .c-grid .c-row .c-day .event-n-holder{height:90%;height:-moz-calc(100% - 10px);height:-o-calc(100% - 10px);height:-webkit-calc(100% - 10px);height:calc(100% - 10px);left:5%;left:-moz-calc(0px + 5px);left:-o-calc(0px + 5px);left:-webkit-calc(0px + 5px);left:calc(0px + 5px);top:5%;top:-moz-calc(0px + 5px);top:-o-calc(0px + 5px);top:-webkit-calc(0px + 5px);top:calc(0px + 5px);position:absolute;width:0.25em}[kalendar] .c-grid .c-row .c-day .event-n-holder .event-n{height:0.5em;background-color:white;width:100%;margin:1px 0}[kalendar] .c-specific{position:absolute;width:100%;height:100%;left:0;top:0;display:none;padding:1px;padding-top:0px}[kalendar] .c-specific .specific-day{vertical-align:top;width:30%;display:inline-block;line-height:1;padding:1em 0;cursor:pointer;text-align:center}[kalendar] .c-specific .specific-day:hover{background:#232323}[kalendar] .c-specific .specific-day [i=date]{font-size:3em}[kalendar] .c-specific .specific-day [i=day]{font-size:1.5em}[kalendar] .c-specific .s-scheme{display:inline-block;height:100%;margin-left:1px;width:60%;width:-moz-calc(70% - 1px);width:-o-calc(70% - 1px);width:-webkit-calc(70% - 1px);width:calc(70% - 1px);overflow-y:auto;text-align:left;vertical-align:top}[kalendar] .c-specific .s-scheme::-webkit-scrollbar{width:10px}[kalendar] .c-specific .s-scheme::-webkit-scrollbar-track{background:transparent}[kalendar] .c-specific .s-scheme::-webkit-scrollbar-thumb{background:#232323}[kalendar] .c-specific .s-scheme .s-event{width:100%;padding:0.5em;margin:1px 0}[kalendar] .c-specific .s-scheme .s-event:first-child{margin-top:0}[kalendar] .c-specific .s-scheme .s-event:last-child{margin-bottom:0}[kalendar] .c-specific .s-scheme .s-event h5{margin:0;font-size:1.1em;line-height:1.3;font-weight:400;color:white}[kalendar] .c-specific .s-scheme .s-event p{margin:0;color:rgba(255,255,255,0.56);line-height:1.3}[kalendar] .c-specific .s-scheme .s-event a{font-weight:normal}[kalendar] .c-specific .s-scheme .s-event p[data-role=loc]{line-height:1}[kalendar]:hover .c-month-view{background:#232323 !important}[kalendar]:hover .c-month-view [class^=c-month-arrow]{color:white}[kalendar].spec-day .c-grid{display:none}[kalendar].spec-day .c-specific{display:block}[kalendar].spec-day [class^=c-month-arrow]{display:none}[kalendar][touch-enabled=true] .c-month-view [class^=c-month-arrow]{color:white}[kalendar][showdays=false] .c-holder .c-grid .c-row{height:15.67%;height:-moz-calc(100%/6 - 7px/6);height:-o-calc(100%/6 - 7px/6);height:-webkit-calc(100%/6 - 7px/6);height:calc(100%/6 - 7px/6)}[color=red]{background-color:#E83C2C}[color=red] .c-month-view,[color=red] .c-day,[color=red] .specific-day,[color=red] .s-event{background-color:#C1291B}[color=blue]{background-color:#2497DB}[color=blue] .c-month-view,[color=blue] .c-day,[color=blue] .specific-day,[color=blue] .s-event{background-color:#3081B9}[color=green]{background-color:#2ECC70}[color=green] .c-month-view,[color=green] .c-day,[color=green] .specific-day,[color=green] .s-event{background-color:#28AE61}[color=yellow]{background-color:#F2C30F}[color=yellow] .c-month-view,[color=yellow] .c-day,[color=yellow] .specific-day,[color=yellow] .s-event{background-color:#F39C12}";
style.setAttribute("type", "text/css");
if (style.styleSheet) {
    style.styleSheet.cssText = text
} else {
    var textnode = document.createTextNode(text);
    style.appendChild(textnode)
}
var h = document.getElementsByTagName("head")[0];
h.appendChild(style);