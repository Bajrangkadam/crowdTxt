PGDMP                     	    v            crowdTxt    9.6.10    9.6.10 �    �	           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �	           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �	           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �	           1262    16402    crowdTxt    DATABASE     �   CREATE DATABASE "crowdTxt" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_United States.1252' LC_CTYPE = 'English_United States.1252';
    DROP DATABASE "crowdTxt";
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            �	           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                  postgres    false    3                        3079    12387    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            �	           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1                       1255    17212    authenticate_user(text, text)    FUNCTION     �  CREATE FUNCTION public.authenticate_user(user_email text DEFAULT NULL::text, user_password text DEFAULT NULL::text) RETURNS text
    LANGUAGE plpgsql
    AS $$

	
DECLARE output_json text:='';success_json text:= '';final_message text := '';

BEGIN
		    success_json := success_json || (select array_to_json(array_agg(row)) from (
			select ctu.user_id as userid, ccm.is_inital_setup_done as setupdone,ctu.role_name as role,ctu.first_name as firstname,ctu.last_name as lastname,
				ccm.company_name as companyname,ctu.email_id as emaid from ct_user_master ctu
				left join ct_company_master ccm on ccm.company_id = ctu.company_id
				where ctu.email_id = user_email and ctu.password = user_password)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": 200, "message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": 404, "message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END 

$$;
 M   DROP FUNCTION public.authenticate_user(user_email text, user_password text);
       public       postgres    false    1    3                        1255    17216 2   company_signup(text, text, text, integer, integer)    FUNCTION     �  CREATE FUNCTION public.company_signup(company_name text DEFAULT NULL::text, company_password text DEFAULT NULL::text, company_email text DEFAULT NULL::text, company_otp integer DEFAULT NULL::integer, company_taxid integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$

declare 
	success_json text:= '';
	output_json text := '';
	final_message text := '';
	userId text = '';
	tran_companyid integer = null;
	tran_userid integer = null;
	current_date_time timestamp with time zone  := now() AT TIME ZONE 'UTC';
BEGIN	
		userId := (select array_to_json(array_agg(row)) from (
			select user_id from public.ct_user_master where email_id = company_email and is_active = 'Y')row);
		
		IF (length(userId) != 0) THEN
            	final_message:='Email Already Exist';
            	RETURN '{ "status": 409,"message": "'|| final_message ||'", "error": [] ,"data":[] }';
        ELSE	
			
			drop table if exists inserted_company_detl;		
			create temp table inserted_company_detl
			(
				tran_company_id integer
			);
			
        	with inserted_companyMaster as (
 			INSERT INTO public.ct_company_master(company_name,company_tax_id, created_date, is_active,
 				is_inital_setup_done)
 			VALUES(company_name,company_taxid,current_date_time,'Y','N')
 			returning company_id as company_master_id
 		   )
			insert into inserted_company_detl (tran_company_id)
			select company_master_id from inserted_companyMaster;
			
			tran_companyid := (select tran_company_id from inserted_company_detl);
			raise notice 'CompanyId: %', tran_companyid;
			drop table if exists inserted_user_detl;		
			create temp table inserted_user_detl
			(
				tran_user_id integer
			);							
			with inserted_userMaster as (
				INSERT INTO public.ct_user_master(email_id,password,role_name,is_active,created_by,
								created_date,status,company_id,email_otp)				
			VALUES(company_email,company_password,'ROLE_ADMIN','Y',tran_companyid,current_date_time,'Subscribed',tran_companyid,company_otp)
			returning user_id as user_return_id
		   )
			insert into inserted_user_detl (tran_user_id)
			select user_return_id from inserted_userMaster;
										
			tran_userid := (select tran_user_id from inserted_user_detl);
			raise notice 'userId: %', tran_userid;	   
												  
			update ct_company_master set user_id =tran_userid where company_id=tran_companyid;
			
			success_json := success_json || (select array_to_json(array_agg(row)) from (		    
		    select csp.plan_id as companyplanid, cm.company_name as companyname,um.email_id as emailid,csp.plan_name as planname from ct_company_master cm 
			left join ct_user_master um on cm.user_id=um.user_id
			left join ct_subscription_plans csp on csp.plan_id=cm.company_tax_id and cm.is_active = 'Y'
			where um.email_id=company_email
			)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": 201,"message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": 404,"message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END IF;	    
END;

$$;
 �   DROP FUNCTION public.company_signup(company_name text, company_password text, company_email text, company_otp integer, company_taxid integer);
       public       postgres    false    3    1            �            1255    17214    get_company_info(integer)    FUNCTION     �  CREATE FUNCTION public.get_company_info(companyid integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$

	
DECLARE output_json text:='';success_json text:= '';final_message text := '';

BEGIN
		    success_json := success_json || (select array_to_json(array_agg(row)) from (
			select ctu.user_id as userid, ccm.is_inital_setup_done as setupdone,ctu.role_name as role,ctu.first_name as firstname,ctu.last_name as lastname,
				ccm.company_name as companyname,ctu.email_id as email,ctu.phone,ctu.is_emailotpverified as isMailOtpVerified from ct_user_master ctu
				left join ct_company_master ccm on ccm.company_id = ctu.company_id				
				where ctu.user_id = companyid
			)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END 

$$;
 :   DROP FUNCTION public.get_company_info(companyid integer);
       public       postgres    false    3    1            �            1255    16837    get_company_master(integer)    FUNCTION     Z  CREATE FUNCTION public.get_company_master(companyid integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	
DECLARE output_json text:='';success_json text:= '';final_message text := '';

BEGIN
		    success_json := success_json || (select array_to_json(array_agg(row)) from (
			select * from ct_company_master where company_id = companyid)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END 
$$;
 <   DROP FUNCTION public.get_company_master(companyid integer);
       public       postgres    false    3    1            �            1255    16839    get_plan_detail_by_id(integer)    FUNCTION       CREATE FUNCTION public.get_plan_detail_by_id(planid integer DEFAULT NULL::integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
	
DECLARE output_json text:='';success_json text:= '';final_message text := '';

BEGIN
		    success_json := success_json || (select array_to_json(array_agg(row)) from (
			select plan_id as planId,no_of_msgs as noOfMsgs, no_of_users as noOfUsers, plan_name as planName ,created_by as createdBy,created_date as createdDate,is_active as isActive 
			from ct_subscription_plans where plan_id = planid
			)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END 
$$;
 <   DROP FUNCTION public.get_plan_detail_by_id(planid integer);
       public       postgres    false    1    3            �            1255    16838    get_plan_details()    FUNCTION     �  CREATE FUNCTION public.get_plan_details() RETURNS text
    LANGUAGE plpgsql
    AS $$
	
DECLARE output_json text:='';success_json text:= '';final_message text := '';

BEGIN
		    success_json := success_json || (select array_to_json(array_agg(row)) from (
			select plan_id as planId,no_of_msgs as noOfMsgs, no_of_users as noOfUsers, plan_name as planName ,created_by as createdBy,created_date as createdDate,is_active as isActive from ct_subscription_plans
			)row);
				
            IF (length(success_json) > 0) THEN
            	final_message:='Record found successfully';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":' || trim(trailing ',' from success_json) || ' }';
        	ELSE
            	final_message:='No record found';
            	output_json := '{ "status": "success", "message": "'|| final_message ||'", "error": [] ,"data":[] }';
        	END IF;
	return output_json;
END 
$$;
 )   DROP FUNCTION public.get_plan_details();
       public       postgres    false    1    3            �            1259    17120    company_id_seq    SEQUENCE     v   CREATE SEQUENCE public.company_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.company_id_seq;
       public       postgres    false    3            �            1259    16406    ct_comment_reply    TABLE     �  CREATE TABLE public.ct_comment_reply (
    reply_id integer NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    reply_by integer NOT NULL,
    reply_date timestamp(0) without time zone NOT NULL,
    reply_description character varying NOT NULL,
    comment_id integer NOT NULL
);
 $   DROP TABLE public.ct_comment_reply;
       public         postgres    false    3            �            1259    16415    ct_company_master    TABLE     E  CREATE TABLE public.ct_company_master (
    company_id integer DEFAULT nextval('public.company_id_seq'::regclass) NOT NULL,
    company_tax_id integer,
    company_name character varying(255) NOT NULL,
    created_by integer,
    created_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    user_id integer,
    is_inital_setup_done character varying(1) DEFAULT NULL::character varying
);
 %   DROP TABLE public.ct_company_master;
       public         postgres    false    238    3            �            1259    17161    ct_company_plan_mapping    TABLE     �  CREATE TABLE public.ct_company_plan_mapping (
    company_plan_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    transaction_id "char" NOT NULL,
    payment_status "char" NOT NULL,
    amount_paid bigint,
    currency_type "char" NOT NULL,
    created_by integer NOT NULL,
    created_date date NOT NULL,
    modified_by integer NOT NULL,
    modified_date date NOT NULL,
    company_id integer,
    plan_id integer,
    is_active "char" NOT NULL
);
 +   DROP TABLE public.ct_company_plan_mapping;
       public         postgres    false    3            �            1259    16423    ct_event_messages    TABLE       CREATE TABLE public.ct_event_messages (
    event_msg_id integer NOT NULL,
    add_poll character varying(1) DEFAULT NULL::character varying,
    add_survey character varying(1) DEFAULT NULL::character varying,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    message character varying NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    event_id integer NOT NULL
);
 %   DROP TABLE public.ct_event_messages;
       public         postgres    false    3            �            1259    16435    ct_group_master    TABLE     �  CREATE TABLE public.ct_group_master (
    group_id integer NOT NULL,
    admin_approved character varying(1) DEFAULT NULL::character varying,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    group_name character varying(255) NOT NULL,
    is_active character varying(1) NOT NULL,
    is_private character varying(1) DEFAULT NULL::character varying,
    is_public character varying(1) DEFAULT NULL::character varying,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    purpose character varying,
    url character varying(255) DEFAULT NULL::character varying,
    company_id integer NOT NULL,
    approver_id integer
);
 #   DROP TABLE public.ct_group_master;
       public         postgres    false    3            �            1259    16449    ct_group_member_mapping    TABLE     �  CREATE TABLE public.ct_group_member_mapping (
    gm_mapping_id integer NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    group_id integer NOT NULL,
    member_id integer NOT NULL
);
 +   DROP TABLE public.ct_group_member_mapping;
       public         postgres    false    3            �            1259    16457    ct_lookup_detail    TABLE     �  CREATE TABLE public.ct_lookup_detail (
    ld_id integer NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    ld_desc character varying NOT NULL,
    ld_name character varying(255) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    parent_id integer,
    lm_id integer NOT NULL
);
 $   DROP TABLE public.ct_lookup_detail;
       public         postgres    false    3            �            1259    16467    ct_lookup_master_seq    SEQUENCE     }   CREATE SEQUENCE public.ct_lookup_master_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.ct_lookup_master_seq;
       public       postgres    false    3            �            1259    16469    ct_lookup_master    TABLE     �  CREATE TABLE public.ct_lookup_master (
    lm_id integer DEFAULT nextval('public.ct_lookup_master_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    lm_desc character varying(255) DEFAULT NULL::character varying,
    lm_name character varying(255) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone
);
 $   DROP TABLE public.ct_lookup_master;
       public         postgres    false    203    3            �            1259    16711    ct_main_event_seq    SEQUENCE     z   CREATE SEQUENCE public.ct_main_event_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.ct_main_event_seq;
       public       postgres    false    3            �            1259    16713    ct_main_event    TABLE     j  CREATE TABLE public.ct_main_event (
    event_id integer DEFAULT nextval('public.ct_main_event_seq'::regclass) NOT NULL,
    allow_private_comments character varying(1) NOT NULL,
    allow_reply character varying(1) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    event_current_status character varying(255) NOT NULL,
    event_admin_id integer NOT NULL,
    event_date timestamp(0) without time zone NOT NULL,
    event_time timestamp(0) without time zone NOT NULL,
    event_title character varying(255) NOT NULL,
    is_active character varying(1) NOT NULL,
    is_poll_enabled character varying(1) NOT NULL,
    is_survey_enabled character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    company_id integer NOT NULL
);
 !   DROP TABLE public.ct_main_event;
       public         postgres    false    234    3            �            1259    16480    ct_message_comments    TABLE     ]  CREATE TABLE public.ct_message_comments (
    comment_id integer NOT NULL,
    attachment_file_path character varying(255) DEFAULT NULL::character varying,
    comment_by integer NOT NULL,
    comment_date timestamp(0) without time zone NOT NULL,
    comment_description text NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    message_id integer NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    event_id integer NOT NULL
);
 '   DROP TABLE public.ct_message_comments;
       public         postgres    false    3            �            1259    16491    ct_message_send_method_map    TABLE     �  CREATE TABLE public.ct_message_send_method_map (
    send_method_map_id integer NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    group_id integer NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    ld_id integer,
    lm_id integer,
    event_id integer NOT NULL
);
 .   DROP TABLE public.ct_message_send_method_map;
       public         postgres    false    3            �            1259    16500    ct_message_user_map    TABLE     �  CREATE TABLE public.ct_message_user_map (
    msg_user_map_id integer NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    user_id integer NOT NULL,
    event_id integer NOT NULL
);
 '   DROP TABLE public.ct_message_user_map;
       public         postgres    false    3            �            1259    16509    ct_notification_info_seq    SEQUENCE     �   CREATE SEQUENCE public.ct_notification_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.ct_notification_info_seq;
       public       postgres    false    3            �            1259    16511    ct_notification_info    TABLE     �  CREATE TABLE public.ct_notification_info (
    notification_id integer DEFAULT nextval('public.ct_notification_info_seq'::regclass) NOT NULL,
    group_id integer NOT NULL,
    notification_sent_by integer NOT NULL,
    notification_created_date timestamp(0) without time zone NOT NULL,
    notification_desc text,
    is_admin_approved character varying(1) DEFAULT NULL::character varying,
    is_requested character varying(4) DEFAULT NULL::character varying
);
 (   DROP TABLE public.ct_notification_info;
       public         postgres    false    208    3            �            1259    16544    ct_notification_response_seq    SEQUENCE     �   CREATE SEQUENCE public.ct_notification_response_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.ct_notification_response_seq;
       public       postgres    false    3            �            1259    16546    ct_notification_response    TABLE     [  CREATE TABLE public.ct_notification_response (
    response_id integer DEFAULT nextval('public.ct_notification_response_seq'::regclass) NOT NULL,
    accept_decline_by integer NOT NULL,
    accept_decline_date timestamp(0) without time zone NOT NULL,
    is_accepted_declined character varying(1) NOT NULL,
    notification_id integer NOT NULL
);
 ,   DROP TABLE public.ct_notification_response;
       public         postgres    false    210    3            �            1259    16553    ct_poll_question_seq    SEQUENCE     }   CREATE SEQUENCE public.ct_poll_question_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.ct_poll_question_seq;
       public       postgres    false    3            �            1259    16555    ct_poll_question    TABLE     �  CREATE TABLE public.ct_poll_question (
    poll_que_id integer DEFAULT nextval('public.ct_poll_question_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(45) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    poll_question character varying(255) NOT NULL,
    event_id integer NOT NULL
);
 $   DROP TABLE public.ct_poll_question;
       public         postgres    false    212    3            �            1259    16563    ct_poll_response_seq    SEQUENCE     }   CREATE SEQUENCE public.ct_poll_response_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.ct_poll_response_seq;
       public       postgres    false    3            �            1259    16565    ct_poll_response    TABLE     J  CREATE TABLE public.ct_poll_response (
    poll_response_id integer DEFAULT nextval('public.ct_poll_response_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(45) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    no_count character varying(255) DEFAULT NULL::character varying,
    yes_count character varying(255) DEFAULT NULL::character varying,
    poll_que_id integer NOT NULL,
    poll_answer text
);
 $   DROP TABLE public.ct_poll_response;
       public         postgres    false    214    3            �            1259    16578    ct_role_master_seq    SEQUENCE     {   CREATE SEQUENCE public.ct_role_master_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.ct_role_master_seq;
       public       postgres    false    3            �            1259    16580    ct_role_master    TABLE     �  CREATE TABLE public.ct_role_master (
    role_id integer DEFAULT nextval('public.ct_role_master_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    no_of_messages integer,
    role_name character varying(255) NOT NULL
);
 "   DROP TABLE public.ct_role_master;
       public         postgres    false    216    3            �            1259    16587    ct_send_to_details_seq    SEQUENCE        CREATE SEQUENCE public.ct_send_to_details_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.ct_send_to_details_seq;
       public       postgres    false    3            �            1259    16589    ct_send_to_details    TABLE     z  CREATE TABLE public.ct_send_to_details (
    send_to_id integer DEFAULT nextval('public.ct_send_to_details_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    send_email_group character varying(255) DEFAULT NULL::character varying,
    send_sms_group character varying(255) DEFAULT NULL::character varying,
    send_to_email character varying(255) DEFAULT NULL::character varying,
    send_to_sms character varying(255) DEFAULT NULL::character varying,
    send_url character varying(255) DEFAULT NULL::character varying,
    sent_email_status character varying(1) NOT NULL,
    sent_sms_status character varying(1) NOT NULL,
    event_id integer NOT NULL
);
 &   DROP TABLE public.ct_send_to_details;
       public         postgres    false    218    3            �            1259    16605    ct_subscription_plans_seq    SEQUENCE     �   CREATE SEQUENCE public.ct_subscription_plans_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.ct_subscription_plans_seq;
       public       postgres    false    3            �            1259    16607    ct_subscription_plans    TABLE       CREATE TABLE public.ct_subscription_plans (
    plan_id integer DEFAULT nextval('public.ct_subscription_plans_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    no_of_msgs integer NOT NULL,
    no_of_users integer NOT NULL,
    plan_name character varying(255) NOT NULL,
    plan_amount integer DEFAULT 0
);
 )   DROP TABLE public.ct_subscription_plans;
       public         postgres    false    220    3            �            1259    16614    ct_survey_master_seq    SEQUENCE     }   CREATE SEQUENCE public.ct_survey_master_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.ct_survey_master_seq;
       public       postgres    false    3            �            1259    16616    ct_survey_master    TABLE     �  CREATE TABLE public.ct_survey_master (
    survey_id integer DEFAULT nextval('public.ct_survey_master_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(45) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    survey_name character varying(255) NOT NULL,
    event_id integer NOT NULL
);
 $   DROP TABLE public.ct_survey_master;
       public         postgres    false    222    3            �            1259    16624    ct_survey_question_seq    SEQUENCE        CREATE SEQUENCE public.ct_survey_question_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.ct_survey_question_seq;
       public       postgres    false    3            �            1259    16626    ct_survey_question    TABLE     �  CREATE TABLE public.ct_survey_question (
    survey_que_id integer DEFAULT nextval('public.ct_survey_question_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(45) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    survey_question character varying(255) NOT NULL,
    survey_id integer NOT NULL
);
 &   DROP TABLE public.ct_survey_question;
       public         postgres    false    224    3            �            1259    16634    ct_survey_question_answer_seq    SEQUENCE     �   CREATE SEQUENCE public.ct_survey_question_answer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.ct_survey_question_answer_seq;
       public       postgres    false    3            �            1259    16636    ct_survey_question_answer    TABLE     �  CREATE TABLE public.ct_survey_question_answer (
    survey_qa_id integer DEFAULT nextval('public.ct_survey_question_answer_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    is_active character varying(45) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    survey_answer character varying(255) NOT NULL,
    survey_que_id integer NOT NULL
);
 -   DROP TABLE public.ct_survey_question_answer;
       public         postgres    false    226    3            �            1259    16644    ct_survey_response_seq    SEQUENCE        CREATE SEQUENCE public.ct_survey_response_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.ct_survey_response_seq;
       public       postgres    false    3            �            1259    16646    ct_survey_response    TABLE       CREATE TABLE public.ct_survey_response (
    survey_response_id integer DEFAULT nextval('public.ct_survey_response_seq'::regclass) NOT NULL,
    created_by integer NOT NULL,
    created_date timestamp(0) without time zone NOT NULL,
    feedback character varying(45) NOT NULL,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    survey_que_id integer NOT NULL,
    survey_answer_id integer NOT NULL
);
 &   DROP TABLE public.ct_survey_response;
       public         postgres    false    228    3            �            1259    16655    ct_user_log_info_seq    SEQUENCE     }   CREATE SEQUENCE public.ct_user_log_info_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.ct_user_log_info_seq;
       public       postgres    false    3            �            1259    16657    ct_user_log_info    TABLE     �  CREATE TABLE public.ct_user_log_info (
    user_log_id integer DEFAULT nextval('public.ct_user_log_info_seq'::regclass) NOT NULL,
    login_datetime timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    logout_datetime timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    session_id character varying(255) NOT NULL,
    user_id integer NOT NULL
);
 $   DROP TABLE public.ct_user_log_info;
       public         postgres    false    230    3            �            1259    16996    user_id_seq    SEQUENCE     s   CREATE SEQUENCE public.user_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.user_id_seq;
       public       postgres    false    3            �            1259    16674    ct_user_master    TABLE     �  CREATE TABLE public.ct_user_master (
    user_id integer DEFAULT nextval('public.user_id_seq'::regclass) NOT NULL,
    address1 character varying(255) DEFAULT NULL::character varying,
    address2 character varying(255) DEFAULT NULL::character varying,
    city character varying(255) DEFAULT NULL::character varying,
    country character varying(255) DEFAULT NULL::character varying,
    created_by integer,
    created_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    gender character varying(255) DEFAULT NULL::character varying,
    is_active character varying(1) NOT NULL,
    modified_by integer,
    modified_date timestamp(0) without time zone DEFAULT NULL::timestamp without time zone,
    otp integer,
    password character varying(255) DEFAULT NULL::character varying,
    email_id character varying(255) DEFAULT NULL::character varying,
    first_name character varying(255) DEFAULT NULL::character varying,
    last_name character varying(255) DEFAULT NULL::character varying,
    phone character varying(20) DEFAULT NULL::character varying,
    status character varying(45) DEFAULT NULL::character varying,
    role_name character varying(255) NOT NULL,
    state character varying(255) DEFAULT NULL::character varying,
    token character varying(90) DEFAULT NULL::character varying,
    zip integer,
    company_id integer NOT NULL,
    password_token character varying(100) DEFAULT NULL::character varying,
    is_otpverified character varying(4) DEFAULT NULL::character varying,
    email_notify character varying(11) DEFAULT NULL::character varying,
    mobile_notify character varying(11) DEFAULT NULL::character varying,
    wrong_email character varying(255) DEFAULT NULL::character varying,
    wrong_phone character varying(255) DEFAULT NULL::character varying,
    is_emailotpverified character varying(4) DEFAULT NULL::character varying,
    email_otp integer
);
 "   DROP TABLE public.ct_user_master;
       public         postgres    false    237    3            �            1259    16672    ct_user_master_seq    SEQUENCE     {   CREATE SEQUENCE public.ct_user_master_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.ct_user_master_seq;
       public       postgres    false    3            �            1259    16887    test_id_seq    SEQUENCE     t   CREATE SEQUENCE public.test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.test_id_seq;
       public       postgres    false    3            �	           0    0    company_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.company_id_seq', 21, true);
            public       postgres    false    238            �	          0    16406    ct_comment_reply 
   TABLE DATA               �   COPY public.ct_comment_reply (reply_id, created_by, created_date, is_active, modified_by, modified_date, reply_by, reply_date, reply_description, comment_id) FROM stdin;
    public       postgres    false    197   �'      �	          0    16415    ct_company_master 
   TABLE DATA               �   COPY public.ct_company_master (company_id, company_tax_id, company_name, created_by, created_date, is_active, modified_by, modified_date, user_id, is_inital_setup_done) FROM stdin;
    public       postgres    false    198   (      �	          0    17161    ct_company_plan_mapping 
   TABLE DATA               �   COPY public.ct_company_plan_mapping (company_plan_id, start_date, end_date, transaction_id, payment_status, amount_paid, currency_type, created_by, created_date, modified_by, modified_date, company_id, plan_id, is_active) FROM stdin;
    public       postgres    false    239   )      �	          0    16423    ct_event_messages 
   TABLE DATA               �   COPY public.ct_event_messages (event_msg_id, add_poll, add_survey, created_by, created_date, is_active, message, modified_by, modified_date, event_id) FROM stdin;
    public       postgres    false    199   4)      �	          0    16435    ct_group_master 
   TABLE DATA               �   COPY public.ct_group_master (group_id, admin_approved, created_by, created_date, group_name, is_active, is_private, is_public, modified_by, modified_date, purpose, url, company_id, approver_id) FROM stdin;
    public       postgres    false    200   Q)      �	          0    16449    ct_group_member_mapping 
   TABLE DATA               �   COPY public.ct_group_member_mapping (gm_mapping_id, created_by, created_date, is_active, modified_by, modified_date, group_id, member_id) FROM stdin;
    public       postgres    false    201   n)      �	          0    16457    ct_lookup_detail 
   TABLE DATA               �   COPY public.ct_lookup_detail (ld_id, created_by, created_date, is_active, ld_desc, ld_name, modified_by, modified_date, parent_id, lm_id) FROM stdin;
    public       postgres    false    202   �)      �	          0    16469    ct_lookup_master 
   TABLE DATA               �   COPY public.ct_lookup_master (lm_id, created_by, created_date, is_active, lm_desc, lm_name, modified_by, modified_date) FROM stdin;
    public       postgres    false    204   �)      �	           0    0    ct_lookup_master_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ct_lookup_master_seq', 1, false);
            public       postgres    false    203            �	          0    16713    ct_main_event 
   TABLE DATA                 COPY public.ct_main_event (event_id, allow_private_comments, allow_reply, created_by, created_date, event_current_status, event_admin_id, event_date, event_time, event_title, is_active, is_poll_enabled, is_survey_enabled, modified_by, modified_date, company_id) FROM stdin;
    public       postgres    false    235   �)      �	           0    0    ct_main_event_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.ct_main_event_seq', 1, false);
            public       postgres    false    234            �	          0    16480    ct_message_comments 
   TABLE DATA               �   COPY public.ct_message_comments (comment_id, attachment_file_path, comment_by, comment_date, comment_description, created_by, created_date, is_active, message_id, modified_by, modified_date, event_id) FROM stdin;
    public       postgres    false    205   �)      �	          0    16491    ct_message_send_method_map 
   TABLE DATA               �   COPY public.ct_message_send_method_map (send_method_map_id, created_by, created_date, group_id, is_active, modified_by, modified_date, ld_id, lm_id, event_id) FROM stdin;
    public       postgres    false    206   �)      �	          0    16500    ct_message_user_map 
   TABLE DATA               �   COPY public.ct_message_user_map (msg_user_map_id, created_by, created_date, is_active, modified_by, modified_date, user_id, event_id) FROM stdin;
    public       postgres    false    207   *      �	          0    16511    ct_notification_info 
   TABLE DATA               �   COPY public.ct_notification_info (notification_id, group_id, notification_sent_by, notification_created_date, notification_desc, is_admin_approved, is_requested) FROM stdin;
    public       postgres    false    209   9*      �	           0    0    ct_notification_info_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.ct_notification_info_seq', 1, false);
            public       postgres    false    208            �	          0    16546    ct_notification_response 
   TABLE DATA               �   COPY public.ct_notification_response (response_id, accept_decline_by, accept_decline_date, is_accepted_declined, notification_id) FROM stdin;
    public       postgres    false    211   V*      �	           0    0    ct_notification_response_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.ct_notification_response_seq', 1, false);
            public       postgres    false    210            �	          0    16555    ct_poll_question 
   TABLE DATA               �   COPY public.ct_poll_question (poll_que_id, created_by, created_date, is_active, modified_by, modified_date, poll_question, event_id) FROM stdin;
    public       postgres    false    213   s*      �	           0    0    ct_poll_question_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ct_poll_question_seq', 1, false);
            public       postgres    false    212            �	          0    16565    ct_poll_response 
   TABLE DATA               �   COPY public.ct_poll_response (poll_response_id, created_by, created_date, is_active, modified_by, modified_date, no_count, yes_count, poll_que_id, poll_answer) FROM stdin;
    public       postgres    false    215   �*      �	           0    0    ct_poll_response_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ct_poll_response_seq', 1, false);
            public       postgres    false    214            �	          0    16580    ct_role_master 
   TABLE DATA               �   COPY public.ct_role_master (role_id, created_by, created_date, is_active, modified_by, modified_date, no_of_messages, role_name) FROM stdin;
    public       postgres    false    217   �*      �	           0    0    ct_role_master_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.ct_role_master_seq', 1, false);
            public       postgres    false    216            �	          0    16589    ct_send_to_details 
   TABLE DATA               �   COPY public.ct_send_to_details (send_to_id, created_by, created_date, is_active, modified_by, modified_date, send_email_group, send_sms_group, send_to_email, send_to_sms, send_url, sent_email_status, sent_sms_status, event_id) FROM stdin;
    public       postgres    false    219   �*      �	           0    0    ct_send_to_details_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.ct_send_to_details_seq', 1, false);
            public       postgres    false    218            �	          0    16607    ct_subscription_plans 
   TABLE DATA               �   COPY public.ct_subscription_plans (plan_id, created_by, created_date, is_active, modified_by, modified_date, no_of_msgs, no_of_users, plan_name, plan_amount) FROM stdin;
    public       postgres    false    221   �*      �	           0    0    ct_subscription_plans_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.ct_subscription_plans_seq', 1, false);
            public       postgres    false    220            �	          0    16616    ct_survey_master 
   TABLE DATA               �   COPY public.ct_survey_master (survey_id, created_by, created_date, is_active, modified_by, modified_date, survey_name, event_id) FROM stdin;
    public       postgres    false    223   X+      �	           0    0    ct_survey_master_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.ct_survey_master_seq', 1, false);
            public       postgres    false    222            �	          0    16626    ct_survey_question 
   TABLE DATA               �   COPY public.ct_survey_question (survey_que_id, created_by, created_date, is_active, modified_by, modified_date, survey_question, survey_id) FROM stdin;
    public       postgres    false    225   u+      �	          0    16636    ct_survey_question_answer 
   TABLE DATA               �   COPY public.ct_survey_question_answer (survey_qa_id, created_by, created_date, is_active, modified_by, modified_date, survey_answer, survey_que_id) FROM stdin;
    public       postgres    false    227   �+      �	           0    0    ct_survey_question_answer_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.ct_survey_question_answer_seq', 1, false);
            public       postgres    false    226            �	           0    0    ct_survey_question_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.ct_survey_question_seq', 1, false);
            public       postgres    false    224            �	          0    16646    ct_survey_response 
   TABLE DATA               �   COPY public.ct_survey_response (survey_response_id, created_by, created_date, feedback, is_active, modified_by, modified_date, survey_que_id, survey_answer_id) FROM stdin;
    public       postgres    false    229   �+      �	           0    0    ct_survey_response_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.ct_survey_response_seq', 1, false);
            public       postgres    false    228            �	          0    16657    ct_user_log_info 
   TABLE DATA               m   COPY public.ct_user_log_info (user_log_id, login_datetime, logout_datetime, session_id, user_id) FROM stdin;
    public       postgres    false    231   �+      �	           0    0    ct_user_log_info_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.ct_user_log_info_seq', 89, false);
            public       postgres    false    230            �	          0    16674    ct_user_master 
   TABLE DATA               }  COPY public.ct_user_master (user_id, address1, address2, city, country, created_by, created_date, gender, is_active, modified_by, modified_date, otp, password, email_id, first_name, last_name, phone, status, role_name, state, token, zip, company_id, password_token, is_otpverified, email_notify, mobile_notify, wrong_email, wrong_phone, is_emailotpverified, email_otp) FROM stdin;
    public       postgres    false    233   �+      �	           0    0    ct_user_master_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.ct_user_master_seq', 11, true);
            public       postgres    false    232            �	           0    0    test_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.test_id_seq', 21, true);
            public       postgres    false    236            �	           0    0    user_id_seq    SEQUENCE SET     :   SELECT pg_catalog.setval('public.user_id_seq', 29, true);
            public       postgres    false    237            �           2606    16414 &   ct_comment_reply ct_comment_reply_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.ct_comment_reply
    ADD CONSTRAINT ct_comment_reply_pkey PRIMARY KEY (reply_id);
 P   ALTER TABLE ONLY public.ct_comment_reply DROP CONSTRAINT ct_comment_reply_pkey;
       public         postgres    false    197    197            �           2606    16422 (   ct_company_master ct_company_master_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.ct_company_master
    ADD CONSTRAINT ct_company_master_pkey PRIMARY KEY (company_id);
 R   ALTER TABLE ONLY public.ct_company_master DROP CONSTRAINT ct_company_master_pkey;
       public         postgres    false    198    198            �           2606    16433 (   ct_event_messages ct_event_messages_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.ct_event_messages
    ADD CONSTRAINT ct_event_messages_pkey PRIMARY KEY (event_msg_id);
 R   ALTER TABLE ONLY public.ct_event_messages DROP CONSTRAINT ct_event_messages_pkey;
       public         postgres    false    199    199            �           2606    16447 $   ct_group_master ct_group_master_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.ct_group_master
    ADD CONSTRAINT ct_group_master_pkey PRIMARY KEY (group_id);
 N   ALTER TABLE ONLY public.ct_group_master DROP CONSTRAINT ct_group_master_pkey;
       public         postgres    false    200    200            �           2606    16454 4   ct_group_member_mapping ct_group_member_mapping_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.ct_group_member_mapping
    ADD CONSTRAINT ct_group_member_mapping_pkey PRIMARY KEY (gm_mapping_id);
 ^   ALTER TABLE ONLY public.ct_group_member_mapping DROP CONSTRAINT ct_group_member_mapping_pkey;
       public         postgres    false    201    201            �           2606    16465 &   ct_lookup_detail ct_lookup_detail_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.ct_lookup_detail
    ADD CONSTRAINT ct_lookup_detail_pkey PRIMARY KEY (ld_id);
 P   ALTER TABLE ONLY public.ct_lookup_detail DROP CONSTRAINT ct_lookup_detail_pkey;
       public         postgres    false    202    202            �           2606    16479 &   ct_lookup_master ct_lookup_master_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.ct_lookup_master
    ADD CONSTRAINT ct_lookup_master_pkey PRIMARY KEY (lm_id);
 P   ALTER TABLE ONLY public.ct_lookup_master DROP CONSTRAINT ct_lookup_master_pkey;
       public         postgres    false    204    204            	           2606    16722     ct_main_event ct_main_event_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.ct_main_event
    ADD CONSTRAINT ct_main_event_pkey PRIMARY KEY (event_id);
 J   ALTER TABLE ONLY public.ct_main_event DROP CONSTRAINT ct_main_event_pkey;
       public         postgres    false    235    235            �           2606    16489 ,   ct_message_comments ct_message_comments_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.ct_message_comments
    ADD CONSTRAINT ct_message_comments_pkey PRIMARY KEY (comment_id);
 V   ALTER TABLE ONLY public.ct_message_comments DROP CONSTRAINT ct_message_comments_pkey;
       public         postgres    false    205    205            �           2606    16496 :   ct_message_send_method_map ct_message_send_method_map_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_send_method_map
    ADD CONSTRAINT ct_message_send_method_map_pkey PRIMARY KEY (send_method_map_id);
 d   ALTER TABLE ONLY public.ct_message_send_method_map DROP CONSTRAINT ct_message_send_method_map_pkey;
       public         postgres    false    206    206            �           2606    16505 ,   ct_message_user_map ct_message_user_map_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.ct_message_user_map
    ADD CONSTRAINT ct_message_user_map_pkey PRIMARY KEY (msg_user_map_id);
 V   ALTER TABLE ONLY public.ct_message_user_map DROP CONSTRAINT ct_message_user_map_pkey;
       public         postgres    false    207    207            �           2606    16521 .   ct_notification_info ct_notification_info_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY public.ct_notification_info
    ADD CONSTRAINT ct_notification_info_pkey PRIMARY KEY (notification_id);
 X   ALTER TABLE ONLY public.ct_notification_info DROP CONSTRAINT ct_notification_info_pkey;
       public         postgres    false    209    209            �           2606    16551 6   ct_notification_response ct_notification_response_pkey 
   CONSTRAINT     }   ALTER TABLE ONLY public.ct_notification_response
    ADD CONSTRAINT ct_notification_response_pkey PRIMARY KEY (response_id);
 `   ALTER TABLE ONLY public.ct_notification_response DROP CONSTRAINT ct_notification_response_pkey;
       public         postgres    false    211    211            �           2606    16561 &   ct_poll_question ct_poll_question_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.ct_poll_question
    ADD CONSTRAINT ct_poll_question_pkey PRIMARY KEY (poll_que_id);
 P   ALTER TABLE ONLY public.ct_poll_question DROP CONSTRAINT ct_poll_question_pkey;
       public         postgres    false    213    213            �           2606    16576 &   ct_poll_response ct_poll_response_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.ct_poll_response
    ADD CONSTRAINT ct_poll_response_pkey PRIMARY KEY (poll_response_id);
 P   ALTER TABLE ONLY public.ct_poll_response DROP CONSTRAINT ct_poll_response_pkey;
       public         postgres    false    215    215            �           2606    16586 "   ct_role_master ct_role_master_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.ct_role_master
    ADD CONSTRAINT ct_role_master_pkey PRIMARY KEY (role_id);
 L   ALTER TABLE ONLY public.ct_role_master DROP CONSTRAINT ct_role_master_pkey;
       public         postgres    false    217    217            �           2606    16603 *   ct_send_to_details ct_send_to_details_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.ct_send_to_details
    ADD CONSTRAINT ct_send_to_details_pkey PRIMARY KEY (send_to_id);
 T   ALTER TABLE ONLY public.ct_send_to_details DROP CONSTRAINT ct_send_to_details_pkey;
       public         postgres    false    219    219            �           2606    16613 0   ct_subscription_plans ct_subscription_plans_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.ct_subscription_plans
    ADD CONSTRAINT ct_subscription_plans_pkey PRIMARY KEY (plan_id);
 Z   ALTER TABLE ONLY public.ct_subscription_plans DROP CONSTRAINT ct_subscription_plans_pkey;
       public         postgres    false    221    221            �           2606    16622 &   ct_survey_master ct_survey_master_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.ct_survey_master
    ADD CONSTRAINT ct_survey_master_pkey PRIMARY KEY (survey_id);
 P   ALTER TABLE ONLY public.ct_survey_master DROP CONSTRAINT ct_survey_master_pkey;
       public         postgres    false    223    223            �           2606    16642 8   ct_survey_question_answer ct_survey_question_answer_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_question_answer
    ADD CONSTRAINT ct_survey_question_answer_pkey PRIMARY KEY (survey_qa_id);
 b   ALTER TABLE ONLY public.ct_survey_question_answer DROP CONSTRAINT ct_survey_question_answer_pkey;
       public         postgres    false    227    227            �           2606    16632 *   ct_survey_question ct_survey_question_pkey 
   CONSTRAINT     s   ALTER TABLE ONLY public.ct_survey_question
    ADD CONSTRAINT ct_survey_question_pkey PRIMARY KEY (survey_que_id);
 T   ALTER TABLE ONLY public.ct_survey_question DROP CONSTRAINT ct_survey_question_pkey;
       public         postgres    false    225    225            �           2606    16652 *   ct_survey_response ct_survey_response_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.ct_survey_response
    ADD CONSTRAINT ct_survey_response_pkey PRIMARY KEY (survey_response_id);
 T   ALTER TABLE ONLY public.ct_survey_response DROP CONSTRAINT ct_survey_response_pkey;
       public         postgres    false    229    229            �           2606    16664 &   ct_user_log_info ct_user_log_info_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.ct_user_log_info
    ADD CONSTRAINT ct_user_log_info_pkey PRIMARY KEY (user_log_id);
 P   ALTER TABLE ONLY public.ct_user_log_info DROP CONSTRAINT ct_user_log_info_pkey;
       public         postgres    false    231    231            	           2606    16704 "   ct_user_master ct_user_master_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.ct_user_master
    ADD CONSTRAINT ct_user_master_pkey PRIMARY KEY (user_id);
 L   ALTER TABLE ONLY public.ct_user_master DROP CONSTRAINT ct_user_master_pkey;
       public         postgres    false    233    233            		           2606    17165 /   ct_company_plan_mapping pk_company_plan_mapping 
   CONSTRAINT     z   ALTER TABLE ONLY public.ct_company_plan_mapping
    ADD CONSTRAINT pk_company_plan_mapping PRIMARY KEY (company_plan_id);
 Y   ALTER TABLE ONLY public.ct_company_plan_mapping DROP CONSTRAINT pk_company_plan_mapping;
       public         postgres    false    239    239            	           2606    16666 -   ct_user_log_info uk_t9t2s33ejk64f87ms22j4hq9s 
   CONSTRAINT     n   ALTER TABLE ONLY public.ct_user_log_info
    ADD CONSTRAINT uk_t9t2s33ejk64f87ms22j4hq9s UNIQUE (session_id);
 W   ALTER TABLE ONLY public.ct_user_log_info DROP CONSTRAINT uk_t9t2s33ejk64f87ms22j4hq9s;
       public         postgres    false    231    231            	           1259    16705    fk_3kooloiv245a73vlsmpbox0gt    INDEX     ]   CREATE INDEX fk_3kooloiv245a73vlsmpbox0gt ON public.ct_user_master USING btree (company_id);
 0   DROP INDEX public.fk_3kooloiv245a73vlsmpbox0gt;
       public         postgres    false    233            �           1259    16552    fk_3nh068eub7qxbx5n1tdnjf54n    INDEX     l   CREATE INDEX fk_3nh068eub7qxbx5n1tdnjf54n ON public.ct_notification_response USING btree (notification_id);
 0   DROP INDEX public.fk_3nh068eub7qxbx5n1tdnjf54n;
       public         postgres    false    211            �           1259    16623    fk_8v7to8qtk8b78h54q5qcgkk0v    INDEX     ]   CREATE INDEX fk_8v7to8qtk8b78h54q5qcgkk0v ON public.ct_survey_master USING btree (event_id);
 0   DROP INDEX public.fk_8v7to8qtk8b78h54q5qcgkk0v;
       public         postgres    false    223            �           1259    16604    fk_9mv9rfiqnep6oi0gpcnoml8tw    INDEX     _   CREATE INDEX fk_9mv9rfiqnep6oi0gpcnoml8tw ON public.ct_send_to_details USING btree (event_id);
 0   DROP INDEX public.fk_9mv9rfiqnep6oi0gpcnoml8tw;
       public         postgres    false    219            �           1259    16455    fk_a0dax9e1dryofnw8roldvhe83    INDEX     d   CREATE INDEX fk_a0dax9e1dryofnw8roldvhe83 ON public.ct_group_member_mapping USING btree (group_id);
 0   DROP INDEX public.fk_a0dax9e1dryofnw8roldvhe83;
       public         postgres    false    201            �           1259    16562    fk_c0h8buet9rtnndaweei4xr2mq    INDEX     ]   CREATE INDEX fk_c0h8buet9rtnndaweei4xr2mq ON public.ct_poll_question USING btree (event_id);
 0   DROP INDEX public.fk_c0h8buet9rtnndaweei4xr2mq;
       public         postgres    false    213            �           1259    16448    fk_dadjfadjfadhk_idx    INDEX     V   CREATE INDEX fk_dadjfadjfadhk_idx ON public.ct_group_master USING btree (company_id);
 (   DROP INDEX public.fk_dadjfadjfadhk_idx;
       public         postgres    false    200            �           1259    16577    fk_djwlpp73hqagyid82fdilkvr1    INDEX     `   CREATE INDEX fk_djwlpp73hqagyid82fdilkvr1 ON public.ct_poll_response USING btree (poll_que_id);
 0   DROP INDEX public.fk_djwlpp73hqagyid82fdilkvr1;
       public         postgres    false    215            �           1259    16653    fk_dp0pgsipqmx52rjvianm6mmvi    INDEX     d   CREATE INDEX fk_dp0pgsipqmx52rjvianm6mmvi ON public.ct_survey_response USING btree (survey_que_id);
 0   DROP INDEX public.fk_dp0pgsipqmx52rjvianm6mmvi;
       public         postgres    false    229            �           1259    16498    fk_fo7rvjvkume50ex3spkvnafir    INDEX     d   CREATE INDEX fk_fo7rvjvkume50ex3spkvnafir ON public.ct_message_send_method_map USING btree (lm_id);
 0   DROP INDEX public.fk_fo7rvjvkume50ex3spkvnafir;
       public         postgres    false    206            �           1259    16667    fk_g1yikl79hdq7qq7n2mjytuutu    INDEX     \   CREATE INDEX fk_g1yikl79hdq7qq7n2mjytuutu ON public.ct_user_log_info USING btree (user_id);
 0   DROP INDEX public.fk_g1yikl79hdq7qq7n2mjytuutu;
       public         postgres    false    231            �           1259    16643    fk_gnpfbyq7jt2cwpc8hg5t9quwm    INDEX     k   CREATE INDEX fk_gnpfbyq7jt2cwpc8hg5t9quwm ON public.ct_survey_question_answer USING btree (survey_que_id);
 0   DROP INDEX public.fk_gnpfbyq7jt2cwpc8hg5t9quwm;
       public         postgres    false    227            �           1259    16506    fk_h9cr464ke623wwd8fu6bxp38o    INDEX     `   CREATE INDEX fk_h9cr464ke623wwd8fu6bxp38o ON public.ct_message_user_map USING btree (event_id);
 0   DROP INDEX public.fk_h9cr464ke623wwd8fu6bxp38o;
       public         postgres    false    207            	           1259    16723    fk_hhddakhgajf_idx    INDEX     R   CREATE INDEX fk_hhddakhgajf_idx ON public.ct_main_event USING btree (company_id);
 &   DROP INDEX public.fk_hhddakhgajf_idx;
       public         postgres    false    235            �           1259    16434    fk_irg3bu1o47nsjifi9d2tkbfh2    INDEX     ^   CREATE INDEX fk_irg3bu1o47nsjifi9d2tkbfh2 ON public.ct_event_messages USING btree (event_id);
 0   DROP INDEX public.fk_irg3bu1o47nsjifi9d2tkbfh2;
       public         postgres    false    199            �           1259    16466    fk_j3vc6rd67sq9j0sjxs9d35nrq    INDEX     Z   CREATE INDEX fk_j3vc6rd67sq9j0sjxs9d35nrq ON public.ct_lookup_detail USING btree (lm_id);
 0   DROP INDEX public.fk_j3vc6rd67sq9j0sjxs9d35nrq;
       public         postgres    false    202            �           1259    16490    fk_kbgdufy1f6skwrjfuohko539o    INDEX     `   CREATE INDEX fk_kbgdufy1f6skwrjfuohko539o ON public.ct_message_comments USING btree (event_id);
 0   DROP INDEX public.fk_kbgdufy1f6skwrjfuohko539o;
       public         postgres    false    205            �           1259    16654    fk_m7fkj7ctrp5vctftc094w7hnx    INDEX     g   CREATE INDEX fk_m7fkj7ctrp5vctftc094w7hnx ON public.ct_survey_response USING btree (survey_answer_id);
 0   DROP INDEX public.fk_m7fkj7ctrp5vctftc094w7hnx;
       public         postgres    false    229            �           1259    16499    fk_my292x4c8bg2til4hgqhyfxlh    INDEX     g   CREATE INDEX fk_my292x4c8bg2til4hgqhyfxlh ON public.ct_message_send_method_map USING btree (event_id);
 0   DROP INDEX public.fk_my292x4c8bg2til4hgqhyfxlh;
       public         postgres    false    206            �           1259    16633    fk_pkblvpceoq56ds96hgax516vo    INDEX     `   CREATE INDEX fk_pkblvpceoq56ds96hgax516vo ON public.ct_survey_question USING btree (survey_id);
 0   DROP INDEX public.fk_pkblvpceoq56ds96hgax516vo;
       public         postgres    false    225            �           1259    16497    fk_pnc2rkhsxo9o6mslxtvhis1iq    INDEX     d   CREATE INDEX fk_pnc2rkhsxo9o6mslxtvhis1iq ON public.ct_message_send_method_map USING btree (ld_id);
 0   DROP INDEX public.fk_pnc2rkhsxo9o6mslxtvhis1iq;
       public         postgres    false    206            �           1259    16456    fk_r5mpkr2mmkrxnr9nne42s74yg    INDEX     e   CREATE INDEX fk_r5mpkr2mmkrxnr9nne42s74yg ON public.ct_group_member_mapping USING btree (member_id);
 0   DROP INDEX public.fk_r5mpkr2mmkrxnr9nne42s74yg;
       public         postgres    false    201            !	           2606    17166 )   ct_company_plan_mapping FK_company_master    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_company_plan_mapping
    ADD CONSTRAINT "FK_company_master" FOREIGN KEY (company_id) REFERENCES public.ct_company_master(company_id);
 U   ALTER TABLE ONLY public.ct_company_plan_mapping DROP CONSTRAINT "FK_company_master";
       public       postgres    false    198    2243    239            "	           2606    17171 ,   ct_company_plan_mapping FK_subscription_plan    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_company_plan_mapping
    ADD CONSTRAINT "FK_subscription_plan" FOREIGN KEY (plan_id) REFERENCES public.ct_subscription_plans(plan_id);
 X   ALTER TABLE ONLY public.ct_company_plan_mapping DROP CONSTRAINT "FK_subscription_plan";
       public       postgres    false    2287    239    221            	           2606    16829 +   ct_user_master fk_3kooloiv245a73vlsmpbox0gt    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_user_master
    ADD CONSTRAINT fk_3kooloiv245a73vlsmpbox0gt FOREIGN KEY (company_id) REFERENCES public.ct_company_master(company_id);
 U   ALTER TABLE ONLY public.ct_user_master DROP CONSTRAINT fk_3kooloiv245a73vlsmpbox0gt;
       public       postgres    false    198    2243    233            	           2606    16779 5   ct_notification_response fk_3nh068eub7qxbx5n1tdnjf54n    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_notification_response
    ADD CONSTRAINT fk_3nh068eub7qxbx5n1tdnjf54n FOREIGN KEY (notification_id) REFERENCES public.ct_notification_info(notification_id);
 _   ALTER TABLE ONLY public.ct_notification_response DROP CONSTRAINT fk_3nh068eub7qxbx5n1tdnjf54n;
       public       postgres    false    2271    211    209            	           2606    16799 -   ct_survey_master fk_8v7to8qtk8b78h54q5qcgkk0v    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_master
    ADD CONSTRAINT fk_8v7to8qtk8b78h54q5qcgkk0v FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 W   ALTER TABLE ONLY public.ct_survey_master DROP CONSTRAINT fk_8v7to8qtk8b78h54q5qcgkk0v;
       public       postgres    false    2310    235    223            	           2606    16794 /   ct_send_to_details fk_9mv9rfiqnep6oi0gpcnoml8tw    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_send_to_details
    ADD CONSTRAINT fk_9mv9rfiqnep6oi0gpcnoml8tw FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 Y   ALTER TABLE ONLY public.ct_send_to_details DROP CONSTRAINT fk_9mv9rfiqnep6oi0gpcnoml8tw;
       public       postgres    false    235    2310    219            	           2606    16734 4   ct_group_member_mapping fk_a0dax9e1dryofnw8roldvhe83    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_group_member_mapping
    ADD CONSTRAINT fk_a0dax9e1dryofnw8roldvhe83 FOREIGN KEY (group_id) REFERENCES public.ct_group_master(group_id);
 ^   ALTER TABLE ONLY public.ct_group_member_mapping DROP CONSTRAINT fk_a0dax9e1dryofnw8roldvhe83;
       public       postgres    false    2248    201    200            	           2606    16784 -   ct_poll_question fk_c0h8buet9rtnndaweei4xr2mq    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_poll_question
    ADD CONSTRAINT fk_c0h8buet9rtnndaweei4xr2mq FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 W   ALTER TABLE ONLY public.ct_poll_question DROP CONSTRAINT fk_c0h8buet9rtnndaweei4xr2mq;
       public       postgres    false    213    2310    235            	           2606    16729     ct_group_master fk_dadjfadjfadhk    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_group_master
    ADD CONSTRAINT fk_dadjfadjfadhk FOREIGN KEY (company_id) REFERENCES public.ct_company_master(company_id);
 J   ALTER TABLE ONLY public.ct_group_master DROP CONSTRAINT fk_dadjfadjfadhk;
       public       postgres    false    200    2243    198            	           2606    16789 -   ct_poll_response fk_djwlpp73hqagyid82fdilkvr1    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_poll_response
    ADD CONSTRAINT fk_djwlpp73hqagyid82fdilkvr1 FOREIGN KEY (poll_que_id) REFERENCES public.ct_poll_question(poll_que_id);
 W   ALTER TABLE ONLY public.ct_poll_response DROP CONSTRAINT fk_djwlpp73hqagyid82fdilkvr1;
       public       postgres    false    213    215    2276            	           2606    16814 /   ct_survey_response fk_dp0pgsipqmx52rjvianm6mmvi    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_response
    ADD CONSTRAINT fk_dp0pgsipqmx52rjvianm6mmvi FOREIGN KEY (survey_que_id) REFERENCES public.ct_survey_question(survey_que_id);
 Y   ALTER TABLE ONLY public.ct_survey_response DROP CONSTRAINT fk_dp0pgsipqmx52rjvianm6mmvi;
       public       postgres    false    2292    229    225            	           2606    16759 7   ct_message_send_method_map fk_fo7rvjvkume50ex3spkvnafir    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_send_method_map
    ADD CONSTRAINT fk_fo7rvjvkume50ex3spkvnafir FOREIGN KEY (lm_id) REFERENCES public.ct_lookup_master(lm_id);
 a   ALTER TABLE ONLY public.ct_message_send_method_map DROP CONSTRAINT fk_fo7rvjvkume50ex3spkvnafir;
       public       postgres    false    2258    206    204            	           2606    16824 -   ct_user_log_info fk_g1yikl79hdq7qq7n2mjytuutu    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_user_log_info
    ADD CONSTRAINT fk_g1yikl79hdq7qq7n2mjytuutu FOREIGN KEY (user_id) REFERENCES public.ct_user_master(user_id);
 W   ALTER TABLE ONLY public.ct_user_log_info DROP CONSTRAINT fk_g1yikl79hdq7qq7n2mjytuutu;
       public       postgres    false    233    231    2307            	           2606    16809 6   ct_survey_question_answer fk_gnpfbyq7jt2cwpc8hg5t9quwm    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_question_answer
    ADD CONSTRAINT fk_gnpfbyq7jt2cwpc8hg5t9quwm FOREIGN KEY (survey_que_id) REFERENCES public.ct_survey_question(survey_que_id);
 `   ALTER TABLE ONLY public.ct_survey_question_answer DROP CONSTRAINT fk_gnpfbyq7jt2cwpc8hg5t9quwm;
       public       postgres    false    227    225    2292            	           2606    16774 0   ct_message_user_map fk_h9cr464ke623wwd8fu6bxp38o    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_user_map
    ADD CONSTRAINT fk_h9cr464ke623wwd8fu6bxp38o FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 Z   ALTER TABLE ONLY public.ct_message_user_map DROP CONSTRAINT fk_h9cr464ke623wwd8fu6bxp38o;
       public       postgres    false    2310    235    207             	           2606    16749    ct_main_event fk_hhddakhgajf    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_main_event
    ADD CONSTRAINT fk_hhddakhgajf FOREIGN KEY (company_id) REFERENCES public.ct_company_master(company_id) ON UPDATE CASCADE;
 F   ALTER TABLE ONLY public.ct_main_event DROP CONSTRAINT fk_hhddakhgajf;
       public       postgres    false    2243    198    235            	           2606    16724 .   ct_event_messages fk_irg3bu1o47nsjifi9d2tkbfh2    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_event_messages
    ADD CONSTRAINT fk_irg3bu1o47nsjifi9d2tkbfh2 FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 X   ALTER TABLE ONLY public.ct_event_messages DROP CONSTRAINT fk_irg3bu1o47nsjifi9d2tkbfh2;
       public       postgres    false    2310    235    199            	           2606    16744 -   ct_lookup_detail fk_j3vc6rd67sq9j0sjxs9d35nrq    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_lookup_detail
    ADD CONSTRAINT fk_j3vc6rd67sq9j0sjxs9d35nrq FOREIGN KEY (lm_id) REFERENCES public.ct_lookup_master(lm_id);
 W   ALTER TABLE ONLY public.ct_lookup_detail DROP CONSTRAINT fk_j3vc6rd67sq9j0sjxs9d35nrq;
       public       postgres    false    204    202    2258            	           2606    16754 0   ct_message_comments fk_kbgdufy1f6skwrjfuohko539o    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_comments
    ADD CONSTRAINT fk_kbgdufy1f6skwrjfuohko539o FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 Z   ALTER TABLE ONLY public.ct_message_comments DROP CONSTRAINT fk_kbgdufy1f6skwrjfuohko539o;
       public       postgres    false    205    2310    235            	           2606    16819 /   ct_survey_response fk_m7fkj7ctrp5vctftc094w7hnx    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_response
    ADD CONSTRAINT fk_m7fkj7ctrp5vctftc094w7hnx FOREIGN KEY (survey_answer_id) REFERENCES public.ct_survey_question_answer(survey_qa_id);
 Y   ALTER TABLE ONLY public.ct_survey_response DROP CONSTRAINT fk_m7fkj7ctrp5vctftc094w7hnx;
       public       postgres    false    2295    227    229            	           2606    16764 7   ct_message_send_method_map fk_my292x4c8bg2til4hgqhyfxlh    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_send_method_map
    ADD CONSTRAINT fk_my292x4c8bg2til4hgqhyfxlh FOREIGN KEY (event_id) REFERENCES public.ct_main_event(event_id);
 a   ALTER TABLE ONLY public.ct_message_send_method_map DROP CONSTRAINT fk_my292x4c8bg2til4hgqhyfxlh;
       public       postgres    false    2310    235    206            	           2606    16804 /   ct_survey_question fk_pkblvpceoq56ds96hgax516vo    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_survey_question
    ADD CONSTRAINT fk_pkblvpceoq56ds96hgax516vo FOREIGN KEY (survey_id) REFERENCES public.ct_survey_master(survey_id);
 Y   ALTER TABLE ONLY public.ct_survey_question DROP CONSTRAINT fk_pkblvpceoq56ds96hgax516vo;
       public       postgres    false    2289    225    223            	           2606    16769 7   ct_message_send_method_map fk_pnc2rkhsxo9o6mslxtvhis1iq    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_message_send_method_map
    ADD CONSTRAINT fk_pnc2rkhsxo9o6mslxtvhis1iq FOREIGN KEY (ld_id) REFERENCES public.ct_lookup_detail(ld_id);
 a   ALTER TABLE ONLY public.ct_message_send_method_map DROP CONSTRAINT fk_pnc2rkhsxo9o6mslxtvhis1iq;
       public       postgres    false    2255    206    202            	           2606    16739 4   ct_group_member_mapping fk_r5mpkr2mmkrxnr9nne42s74yg    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_group_member_mapping
    ADD CONSTRAINT fk_r5mpkr2mmkrxnr9nne42s74yg FOREIGN KEY (member_id) REFERENCES public.ct_user_master(user_id);
 ^   ALTER TABLE ONLY public.ct_group_member_mapping DROP CONSTRAINT fk_r5mpkr2mmkrxnr9nne42s74yg;
       public       postgres    false    201    2307    233            
	           2606    16706 ,   ct_comment_reply fk_y1us8e74emgso2nagguma631    FK CONSTRAINT     �   ALTER TABLE ONLY public.ct_comment_reply
    ADD CONSTRAINT fk_y1us8e74emgso2nagguma631 FOREIGN KEY (comment_id) REFERENCES public.ct_message_comments(comment_id);
 V   ALTER TABLE ONLY public.ct_comment_reply DROP CONSTRAINT fk_y1us8e74emgso2nagguma631;
       public       postgres    false    2260    197    205            �	      x������ � �      �	     x�}�Aj�0E��)t���ьe�2Ⱦ���E!�R��Z���*��{��k:����/!^L�̫�8Kz�x8�&�����g(�l�T�ȭclM%��v�����.�:7a��@��n��G��Kmt�4:�"�sg,a0����3���܅Y��f�]U(���,���Q8����F�҂��a���(ạ�ʎp����)vjp��&��`�)QbQ49��Pz�cP49�e�L8�K<��A3�q�����4M�7�~��      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	   a   x�3�4�420��5��5�T0��24�22���!C0v��I�4�2�Tnbel	Wnj B��9e�E@�ƨʍ�Lͭ��ʍLAȭ(5�8F��� ���      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	      x������ � �      �	   �  x���KK#A�s�S��U�z��N��A���e�t�Jb����d�z����T�TW�'@���������{XBF|-|H��p��p��w'�O���e��]o�V�7�ϟ�_|{w��R0=n�8Х�JX(X�[�Kq���'	^B+9zv���'�P�A��� H�(���O�$ۢK���L3��m�t@��%�$�^Sh%�5���^N׏�ʩ�Xԥ�6O\� u�qn�φ����>���ѡ����� �h4(_��Q]*�W����.5*���������ѡn!p�!������I0�0E�j,�����t��HÌ�r�b�a���������5R�
,h���oߌld��P�a�iY���bߺ���I(��ž��P]3^�Q�C�>-F?E��m2�j��vE#�S -EP���$p�����,���Չs���b     