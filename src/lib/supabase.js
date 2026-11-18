import {createClient} from "@supabase/supabase-js";
export const supabase=createClient("https://avwsmgmzdfsurztomxbo.supabase.co","sb_publishable_yXonwfuSHUCJ_5wqiuHR8Q_ouRSKDJ_",{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true},realtime:{params:{eventsPerSecond:5}}});
