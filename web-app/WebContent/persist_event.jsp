<%@page import="db.DBConnection"%>
<%@page import="sql.User"%>
<%@page import="sql.Meeting"%>
<%@page import="sql.Lecture"%>
<%@page import="java.util.*"%>
<%@page import="helper.*"%>
<jsp:useBean id="dbaccess" class="db.DBAccess" scope="session" />
<jsp:useBean id="usersession" class="helper.UserSession" scope="session" />

<%! 
//convert month string to month number
public static String getMonthNumber(String month) {
    String monthNumber = null;
    if(month.toLowerCase().compareTo("january")==0)      
        monthNumber = "01";
    if(month.toLowerCase().compareTo("february")==0)      
        monthNumber = "02";
    if(month.toLowerCase().compareTo("march")==0)      
        monthNumber = "03";
    if(month.toLowerCase().compareTo("april")==0)      
        monthNumber = "04";
    if(month.toLowerCase().compareTo("may")==0)      
        monthNumber = "05";
    if(month.toLowerCase().compareTo("june")==0)      
        monthNumber = "06";
    if(month.toLowerCase().compareTo("july")==0)      
        monthNumber = "07";
    if(month.toLowerCase().compareTo("august")==0)      
        monthNumber = "08";
    if(month.toLowerCase().compareTo("september")==0)      
        monthNumber = "09";
    if(month.toLowerCase().compareTo("october")==0)      
        monthNumber = "10";
    if(month.toLowerCase().compareTo("november")==0)      
        monthNumber = "11";
    if(month.toLowerCase().compareTo("december")==0)      
        monthNumber = "12";
    return monthNumber;
}

%>

<% 
	//Start page validation
	String userId = usersession.getUserId();
    GetExceptionLog elog = new GetExceptionLog();
	Boolean isProfessor = false;
	Boolean isSuper = false;
	isProfessor=usersession.isProfessor();
	isSuper =usersession.isSuper();
	if (userId.equals("")) {
		session.setAttribute("redirecturl", request.getRequestURI()+(request.getQueryString()!=null?"?"+request.getQueryString():""));
		response.sendRedirect("index.jsp?message=Please log in");
		return;
	}
	if (dbaccess.getFlagStatus() == false) {
		elog.writeLog("[persist_event:] " + "database connection error /n");
		response.sendRedirect("index.jsp?message=Database connection error");
		return;
	} //End page validation
	
	String message = request.getParameter("message");
	if (message == null || message == "null") {
		message="";
	}
	
	User user = new User(dbaccess);
	Meeting meeting = new Meeting(dbaccess);
	Lecture lecture = new Lecture(dbaccess);
	MyBoolean prof = new MyBoolean();
	ArrayList<ArrayList<String>> latestCreatedSchedule = new ArrayList<ArrayList<String>>();
	ArrayList<ArrayList<String>> latestCreatedMeeting = new ArrayList<ArrayList<String>>();
	HashMap<String, Integer> userSettings = new HashMap<String, Integer>();
	HashMap<String, Integer> meetingSettings = new HashMap<String, Integer>();
	HashMap<String, Integer> roleMask = new HashMap<String, Integer>();
	userSettings = usersession.getUserSettingsMask();
	meetingSettings = usersession.getUserMeetingSettingsMask();
	roleMask = usersession.getRoleMask();
    String fromquickmeeting = request.getParameter("fromquickmeeting");
    String startMonthNumber=null;
    String endMonthNumber=null;
    if(fromquickmeeting==null){
        endMonthNumber = getMonthNumber(request.getParameter("dropdownMonthEnds"));
    }
    startMonthNumber = getMonthNumber(request.getParameter("dropdownMonthStarts"));        
    String title = request.getParameter("eventTitle");
    String inidatetime = request.getParameter("dropdownYearStarts").concat("-").concat(startMonthNumber).concat("-").concat(request.getParameter("dropdownDayStarts")).concat(" ").concat(request.getParameter("startTime")).concat(".0");
    //Validate inidatetime to ensure that it is later than current time
    if (!(Validation.checkStartDateTime(inidatetime))) {
    	if(fromquickmeeting !=null){
    		response.sendRedirect("quickMeeting.jsp?message=" + Validation.getErrMsg());
    	}else{
            response.sendRedirect("create_event.jsp?message=" + Validation.getErrMsg());
    	}
        return;
    }
    String duration = request.getParameter("eventDuration");
    String description = (request.getParameter("eventDescription")!=null)?request.getParameter("eventDescription"):"";
    String eventType = request.getParameter("dropdownEventType");
    String c_id=null;
    String sc_id=null;
    String sc_semesterid=null;
    if(isProfessor && eventType.equals("Lecture")){
	     c_id = request.getParameter("courseCode").split(" ")[0];
	     sc_id = request.getParameter("courseCode").split(" ")[1];
	     sc_semesterid =request.getParameter("courseCode").split(" ")[2];
    }
    if(isSuper && eventType.equals("Lecture")){
         c_id = request.getParameter("courseCode").split(" ")[1];
         sc_id = request.getParameter("courseCode").split(" ")[2];
         sc_semesterid =request.getParameter("courseCode").split(" ")[3];
    }
    String spec = null;
	
    //daily weekly recurrence
	String recurrence = request.getParameter("dropdownRecurrence"); // daily,weekly,monthly
	String repeatEvery = request.getParameter("repeatsEvery"); // daily or weekly is chosen, repeat interval
	String endType = request.getParameter("dropdownEnds"); // on specified date or after number of occurrences
	String numberOfOccurrences = request.getParameter("occurrences"); // if after number of occurrences is chosen, times of repeating
	String repeatEndDate = null;
	if(fromquickmeeting ==null) {
		repeatEndDate=request.getParameter("dropdownYearEnds").concat("-").concat(endMonthNumber).concat("-").concat(request.getParameter("dropdownDayEnds")); // if on specified date is chosen, specified end date
	}
    
	// weekly recurrence, weekday selected	
	String weekString = request.getParameter("weekString");
	
	//monthly recurrence

	String dropdownOccursBy = request.getParameter("dropdownOccursBy");
	String dropdownDayoftheMonth = request.getParameter("dropdownDayoftheMonth"); // when occurs by "day of the month"
    String selectedDayofWeek =  request.getParameter("selectedDayofWeek"); // sunday is 0, saturday is 6
	
	//get proper event "spec" pattern
	if (recurrence.equals("Only once")){
        spec="1";       
    }
    else if(recurrence.equals("Daily")){
        if(endType.equals("After # of occurrence(s)")){
            spec = "2;1;".concat(numberOfOccurrences).concat(";").concat(repeatEvery);
        }
        else{
            spec = "2;2;".concat(repeatEndDate).concat(";").concat(repeatEvery);
        }
    }
    else if(recurrence.equals("Weekly")){
        if(endType.equals("After # of occurrence(s)")){
            spec = "3;1;".concat(numberOfOccurrences).concat(";").concat(repeatEvery).concat(";").concat(weekString);
        }else if(endType.equals("After # of week(s)")){
        	spec = "3;2;".concat(numberOfOccurrences).concat(";").concat(repeatEvery).concat(";").concat(weekString);
        }
         else{
            spec = "3;3;".concat(repeatEndDate).concat(";").concat(repeatEvery).concat(";").concat(weekString);
         }
    }
    else{
        if(dropdownOccursBy.equals("Day of the month")){                  
             spec = "4;1;".concat(numberOfOccurrences).concat(";").concat(repeatEvery).concat(";").concat(dropdownDayoftheMonth);                    
        }
        else{
            spec = "4;2;".concat(numberOfOccurrences).concat(";").concat(repeatEvery).concat(";").concat(selectedDayofWeek);    
        }
    }	
	if(eventType.equals("Meeting")){   //create a meeting event		
	   if(meeting.createMeetingSchedule(title, inidatetime, spec, duration, description, userId)){
		   if(fromquickmeeting !=null){
			   meeting.getLatestCreatedSchduleForUser(latestCreatedSchedule, userId);
			   meeting.getMeetingInfo(latestCreatedMeeting, latestCreatedSchedule.get(0).get(0));
			   response.sendRedirect("add_attendee.jsp?successMessage= Quick Meeting created, please add attendees to your meeting&m_id="+latestCreatedMeeting.get(0).get(1) + "&ms_id=" + latestCreatedSchedule.get(0).get(0));
		   }else{
			   response.sendRedirect("calendar.jsp?successMessage=Meeting schedule created"); 
		   }		   
		   return;
	   }else{
		   response.sendRedirect("calendar.jsp?message=Fail to create meeting schedule");
		   return;
	   }
    }
    else{ //creating a lecture event
        if(lecture.createLectureSchedule(c_id, sc_id, sc_semesterid, inidatetime, spec, duration, description)){
            response.sendRedirect("calendar.jsp?successMessage=Lecture schedule created"); 
            return;
        }else{
        	response.sendRedirect("calendar.jsp?message=Fail to create lecture schedule");
        }
    }	
    
%>
