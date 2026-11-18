import React,{useEffect,useState} from "react";
import {Copy,Wallet,RefreshCw,CheckCircle2,Clock3,ShieldCheck} from "lucide-react";

/**
 * WalletPanel requires an authenticated Supabase client and current user.
 * paymentConfig: {bank_name,account_name,account_number,qr_image_path?}
 */
export default function WalletPanel({supabase,user,isAdmin=false,paymentConfig=null}) {
  const [profile,setProfile]=useState(null),[balance,setBalance]=useState(0),[amount,setAmount]=useState("50000");
  const [requests,setRequests]=useState([]),[adminQueue,setAdminQueue]=useState([]);
  const [busy,setBusy]=useState(false),[message,setMessage]=useState("");
  const notify=(s)=>{setMessage(s);window.setTimeout(()=>setMessage(""),3500);};
  async function refresh(){
    if(!supabase||!user?.id)return;
    const [{data:p,error:pe},{data:b},{data:r}]=await Promise.all([
      supabase.from("users").select("account_code,display_name").eq("id",user.id).single(),
      supabase.from("wallet_balances").select("balance_vnd").eq("user_id",user.id).maybeSingle(),
      supabase.from("wallet_topups").select("*").eq("user_id",user.id).order("created_at",{ascending:false}).limit(30)
    ]);
    if(pe){notify(pe.message);return;}
    setProfile(p);setBalance(b?.balance_vnd||0);setRequests(r||[]);
    if(isAdmin){
      const {data,error}=await supabase.from("wallet_topups").select("*,users(username,display_name)").eq("status","pending").order("created_at",{ascending:true});
      if(error)notify(error.message);else setAdminQueue(data||[]);
    }
  }
  useEffect(()=>{refresh();},[user?.id,isAdmin]);
  const money=n=>new Intl.NumberFormat("vi-VN").format(Number(n||0))+"₫";
  async function createRequest(e){
    e.preventDefault();setBusy(true);
    try{
      const {error}=await supabase.rpc("create_wallet_topup",{p_amount_vnd:Number(amount)});
      if(error)throw error;
      await refresh();notify("Đã tạo yêu cầu nạp. Hãy chuyển khoản đúng mã tài khoản bên dưới.");
    }catch(e){notify(e.message||"Không tạo được yêu cầu.");}
    finally{setBusy(false);}
  }
  async function review(id,approve){
    setBusy(true);
    try{
      const {error}=await supabase.rpc("review_wallet_topup",{p_topup_id:id,p_approve:approve,p_admin_note:null});
      if(error)throw error;
      await refresh();notify(approve?"Đã cộng tiền vào ví thành viên.":"Đã từ chối yêu cầu nạp.");
    }catch(e){notify(e.message||"Không thể xử lý yêu cầu.");}
    finally{setBusy(false);}
  }
  const copy=async value=>{try{await navigator.clipboard.writeText(value);notify("Đã sao chép.");}catch{notify("Không thể sao chép trên trình duyệt này.");}};
  if(!user)return <section className="wallet-panel"><h2>Ví GameVault</h2><p>Đăng nhập để xem mã tài khoản và nạp tiền.</p></section>;
  return <section className="wallet-panel">
    <div className="wallet-heading"><div><span className="wallet-eyebrow">GAMEVAULT WALLET</span><h2>Ví tài khoản</h2></div><button type="button" onClick={refresh} aria-label="Làm mới"><RefreshCw size={17}/></button></div>
    <div className="wallet-balance"><span>Số dư khả dụng</span><strong>{money(balance)}</strong></div>
    <div className="wallet-account-code"><div><small>MÃ ID TÀI KHOẢN CHUYỂN KHOẢN</small><b>{profile?.account_code||"Đang tải..."}</b></div><button type="button" onClick={()=>copy(profile?.account_code||"")}><Copy size={16}/> Sao chép</button></div>
    <form className="wallet-topup-form" onSubmit={createRequest}>
      <label>Số tiền muốn nạp (VND)<input type="number" min="1000" max="100000000" step="1000" value={amount} onChange={e=>setAmount(e.target.value)} required/></label>
      <button disabled={busy} type="submit">{busy?"Đang xử lý...":"Tạo yêu cầu nạp tiền"}</button>
    </form>
    <div className="wallet-transfer">
      <div className="wallet-transfer-title"><Wallet size={18}/> Thông tin chuyển khoản</div>
      {paymentConfig?.qr_image_path&&<img className="wallet-qr" src={paymentConfig.qr_image_path} alt="Mã QR chuyển khoản"/>}
      <p><span>Ngân hàng</span><b>{paymentConfig?.bank_name||"Chưa cấu hình"}</b></p>
      <p><span>Chủ tài khoản</span><b>{paymentConfig?.account_name||"Chưa cấu hình"}</b></p>
      <p><span>Số tài khoản</span><b>{paymentConfig?.account_number||"Chưa cấu hình"}</b></p>
      <p className="wallet-transfer-note"><span>Nội dung chuyển khoản bắt buộc</span><b>{profile?.account_code||"Đang tải..."}</b><button type="button" onClick={()=>copy(profile?.account_code||"")}><Copy size={15}/> Sao chép</button></p>
      <small>Chuyển đúng số tiền và ghi đúng mã ID tài khoản. Admin sẽ đối soát giao dịch rồi cộng tiền thủ công; không gửi mật khẩu hoặc mã OTP cho bất kỳ ai.</small>
    </div>
    <div className="wallet-history"><h3>Lịch sử nạp tiền</h3>{requests.map(r=><div className="wallet-request" key={r.id}><div><b>{money(r.amount_vnd)}</b><small>{new Date(r.created_at).toLocaleString("vi-VN")}</small></div><span className={"wallet-status "+r.status}>{r.status==="pending"?"Chờ xác nhận":r.status==="approved"?"Đã cộng tiền":"Từ chối"}</span></div>)}{!requests.length&&<p>Chưa có yêu cầu nạp tiền.</p>}</div>
    {isAdmin&&<div className="wallet-admin"><h3><ShieldCheck size={17}/> Yêu cầu nạp chờ duyệt</h3>{adminQueue.map(r=><div className="wallet-admin-row" key={r.id}><div><b>{r.users?.display_name||r.users?.username||r.account_code}</b><small>{r.account_code} · {money(r.amount_vnd)}</small></div><button disabled={busy} onClick={()=>review(r.id,true)}><CheckCircle2 size={15}/> Đã nhận tiền</button><button className="wallet-reject" disabled={busy} onClick={()=>review(r.id,false)}>Từ chối</button></div>)}{!adminQueue.length&&<p>Không có yêu cầu đang chờ.</p>}</div>}
    {message&&<div className="wallet-message" role="status">{message}</div>}
  </section>;
}
