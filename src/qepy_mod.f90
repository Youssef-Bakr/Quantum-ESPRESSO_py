MODULE qepy_mod
   USE kinds,                ONLY : DP
   USE qepy_scatter_mod, ONLY : gather_grid, scatter_grid
   USE qepy_common, ONLY : embed_base, input_base
   !
   IMPLICIT NONE
   PUBLIC
   !
   INTERFACE mp_gather
      MODULE PROCEDURE mp_gather_real, mp_gather_complex
   END INTERFACE

   INTERFACE mp_scatter
      MODULE PROCEDURE mp_scatter_real, mp_scatter_complex
   END INTERFACE
   !
CONTAINS

   SUBROUTINE mp_gather_real(fin, fout)
      USE kinds,                ONLY : DP
      USE fft_base,         ONLY : dfftp
      !
      IMPLICIT NONE
      REAL(DP), INTENT(IN) :: fin(:)
      REAL(DP), INTENT(OUT) :: fout(:)
      !
      IF (dfftp%nproc > 1) THEN
         CALL gather_grid(dfftp, fin, fout)
      ELSE
         fout(:) = fin(:)
      ENDIF
   END SUBROUTINE

   SUBROUTINE mp_scatter_real(fin, fout)
      USE kinds,                ONLY : DP
      USE fft_base,         ONLY : dfftp
      !
      IMPLICIT NONE
      REAL(DP), INTENT(IN) :: fin(:)
      REAL(DP), INTENT(OUT) :: fout(:)
      !
      IF (dfftp%nproc > 1) THEN
         CALL scatter_grid(dfftp, fin, fout)
      ELSE
         fout(:) = fin(:)
      ENDIF
   END SUBROUTINE

   SUBROUTINE mp_gather_complex(fin, fout)
      USE kinds,                ONLY : DP
      USE fft_base,         ONLY : dfftp
      !
      IMPLICIT NONE
      COMPLEX(DP), INTENT(IN) :: fin(:)
      COMPLEX(DP), INTENT(OUT) :: fout(:)
      !
      IF (dfftp%nproc > 1) THEN
         CALL gather_grid(dfftp, fin, fout)
      ELSE
         fout(:) = fin(:)
      ENDIF
   END SUBROUTINE

   SUBROUTINE mp_scatter_complex(fin, fout)
      USE kinds,                ONLY : DP
      USE fft_base,         ONLY : dfftp
      !
      IMPLICIT NONE
      COMPLEX(DP), INTENT(IN) :: fin(:)
      COMPLEX(DP), INTENT(OUT) :: fout(:)
      !
      IF (dfftp%nproc > 1) THEN
         CALL scatter_grid(dfftp, fin, fout)
      ELSE
         fout(:) = fin(:)
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_get_rho(rhor, inone)
      USE kinds,                ONLY : DP
      use scf, only: rho !! the charge density and its other components
      USE fft_base,         ONLY : dfftp, dffts
      USE lsda_mod,           ONLY : lsda, nspin, current_spin, isk
      !
      IMPLICIT NONE
      REAL(DP), INTENT(OUT) :: rhor(:,:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      INTEGER  :: ispin, nnr
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      DO ispin = 1, nspin
         IF ( mflag ) THEN
            CALL mp_gather(rho%of_r(:,ispin), rhor(:,ispin))
         ELSE
            nnr=dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p
            rhor(1:nnr,ispin) = rho%of_r(1:nnr,ispin)
         ENDIF
      END DO
   END SUBROUTINE

   SUBROUTINE qepy_set_rho(rhor, inone)
      USE kinds,                ONLY : DP
      USE fft_rho,              ONLY : rho_g2r, rho_r2g
      USE fft_base,         ONLY : dfftp, dffts
      use scf, only: rho !! the charge density and its other components
      USE lsda_mod,           ONLY : lsda, nspin, current_spin, isk
      !
      IMPLICIT NONE
      REAL(DP), INTENT(IN) :: rhor(:,:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      INTEGER  :: ispin, nnr
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      DO ispin = 1, nspin
         IF ( mflag ) THEN
            CALL mp_scatter(rhor(:,ispin), rho%of_r(:,ispin))
         ELSE
            nnr=dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p
            rho%of_r(1:nnr,ispin) = rhor(1:nnr,ispin)
            rho%of_r(nnr:dfftp%nnr,ispin) = 0.d0
         ENDIF
      END DO
      CALL rho_r2g(dfftp, rho%of_r, rho%of_g )
   END SUBROUTINE

   SUBROUTINE qepy_get_rho_core(rhoc, inone)
      USE kinds,                ONLY : DP
      use scf, only: rho_core !! the core charge in real space
      USE fft_base,         ONLY : dfftp, dffts
      IMPLICIT NONE
      REAL(DP), INTENT(OUT) :: rhoc(:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF ( mflag ) THEN
         CALL mp_gather(rho_core, rhoc)
      ELSE
         rhoc = rho_core(1:dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p)
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_set_rho_core(rhoc, inone)
      USE kinds,                ONLY : DP
      use scf, only: rho_core !! the core charge in real space
      USE fft_base,         ONLY : dfftp, dffts
      IMPLICIT NONE
      REAL(DP), INTENT(IN) :: rhoc(:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF ( mflag ) THEN
         CALL mp_scatter(rhoc, rho_core)
      ELSE
         rho_core(1:dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p) = rhoc
         rho_core(dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p+1:dfftp%nnr) = 0.d0
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_set_extpot(embed, vin, inone)
      USE kinds,                ONLY : DP
      USE fft_rho,              ONLY : rho_g2r, rho_r2g
      USE fft_base,         ONLY : dfftp, dffts
      !
      IMPLICIT NONE
      TYPE(embed_base), INTENT(INOUT) :: embed
      REAL(DP), INTENT(IN) :: vin(:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF (ALLOCATED(embed%extpot)) THEN
         IF (SIZE(embed%extpot) /= dfftp%nnr) DEALLOCATE(embed%extpot)
      ENDIF
      IF (.NOT.ALLOCATED(embed%extpot)) ALLOCATE(embed%extpot(dfftp%nnr))
      IF ( mflag ) THEN
         CALL mp_scatter(vin, embed%extpot)
      ELSE
         embed%extpot(1:dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p) = vin
         embed%extpot(dfftp%nr1x* dfftp%my_nr2p* dfftp%my_nr3p+1:dfftp%nnr) = 0.d0
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_get_grid(nr, inone)
      USE kinds,                ONLY : DP
      USE fft_base,             ONLY : dfftp
      !
      IMPLICIT NONE
      INTEGER, INTENT(OUT) :: nr(3)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF ( mflag ) THEN
         nr=(/dfftp%nr1, dfftp%nr2, dfftp%nr3/)
      ELSE
         nr=(/dfftp%nr1x, dfftp%my_nr2p, dfftp%my_nr3p/)
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_get_grid_smooth(nr, inone)
      USE kinds,                ONLY : DP
      USE fft_base,             ONLY : dffts
      !
      IMPLICIT NONE
      INTEGER, INTENT(OUT) :: nr(3)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      LOGICAL :: mflag
      !
      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF ( mflag ) THEN
         nr=(/dffts%nr1, dffts%nr2, dffts%nr3/)
      ELSE
         nr=(/dffts%nr1x, dffts%my_nr2p, dffts%my_nr3p/)
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_set_stdout(fname, uni, append)
      USE io_global,     ONLY : stdout, ionode
      !
      INTEGER                  :: ierr
      CHARACTER(LEN=*),INTENT(IN),OPTIONAL  :: fname
      INTEGER,INTENT(in),OPTIONAL :: uni
      LOGICAL,INTENT(in),OPTIONAL :: append
      !
      LOGICAL :: exst
      !
      IF ( .NOT. present(fname) ) return
      IF ( present(uni) ) THEN
         stdout=uni
      ELSE
         stdout=666
      ENDIF

      !IF(ionode)
      exst=.false.
      IF ( present(append) .and. append) THEN
         INQUIRE (file = TRIM(fname), exist = exst)
      ENDIF

      IF (exst) THEN
         OPEN (UNIT = stdout, FILE = TRIM(fname), FORM = 'formatted', POSITION= 'append', iostat = ierr )
      ELSE
         OPEN (UNIT = stdout, FILE = TRIM(fname), FORM = 'formatted', STATUS = 'unknown', iostat = ierr )
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_write_stdout(fstr)
      USE io_global,     ONLY : stdout, ionode
      !
      INTEGER                  :: ierr
      CHARACTER(LEN=*),INTENT(IN)  :: fstr
      !
      IF(ionode) WRITE(stdout,'(A)') fstr
   END SUBROUTINE

   SUBROUTINE qepy_close_stdout(fname)
      USE io_global,     ONLY : stdout, ionode
      !
      INTEGER                  :: ierr
      CHARACTER(LEN=*),INTENT(IN)  :: fname
      !
      IF(ionode) close(stdout)
   END SUBROUTINE

   SUBROUTINE qepy_get_evc(ik, wfc)
      USE kinds,                ONLY : DP
      USE io_files,             ONLY : iunwfc, nwordwfc
      USE buffers,              ONLY : get_buffer
      USE wavefunctions,        ONLY : evc
      USE klist,                ONLY : nks
      !
      IMPLICIT NONE
      INTEGER,INTENT(IN) :: ik
      COMPLEX(DP), INTENT(OUT),OPTIONAL :: wfc(:,:)
      !
      IF ( nks > 1 ) CALL get_buffer ( evc, nwordwfc, iunwfc, ik )
      IF ( present(wfc) ) THEN
         wfc = evc
      ENDIF
   END SUBROUTINE

   SUBROUTINE qepy_get_wf(ik, ibnd, wf, inone)
      USE kinds,                ONLY : DP
      USE io_files,             ONLY : iunwfc, nwordwfc
      USE buffers,              ONLY : get_buffer
      USE wavefunctions,        ONLY : evc, psic
      USE klist,                ONLY : nks, igk_k, ngk
      USE fft_base,             ONLY : dfftp, dffts
      USE fft_interfaces,       ONLY : invfft
      USE control_flags,        ONLY : diago_full_acc, gamma_only, lxdm, tqr
      !
      IMPLICIT NONE
      INTEGER,INTENT(IN) :: ik, ibnd
      COMPLEX(DP), INTENT(OUT) :: wf(:)
      LOGICAL,INTENT(in),OPTIONAL :: inone
      !
      INTEGER :: j, nnr, npw
      LOGICAL :: mflag
      !
      IF ( dffts%has_task_groups ) THEN
         call errore('qepy_get_wf', 'Sorry this one not support task-group version', 1)
      ENDIF
      !
!$omp parallel
      psic(:) = (0.D0, 0.D0)
      npw=ngk(ik)
      !$omp do
      IF ( gamma_only ) THEN
         psic(dffts%nl (1:npw))  = evc(1:npw,ibnd)
         psic(dffts%nlm(1:npw)) = CONJG( evc(1:npw,ibnd) )
      ELSE
         DO j = 1, npw
            psic(dffts%nl(igk_k(j,ik))) = evc(j,ibnd)
         ENDDO
      END IF
      !$omp end do nowait
!$omp end parallel
      CALL invfft ('Wave', psic, dffts)

      IF ( present(inone) ) THEN
         mflag=inone
      ELSE
         mflag=.true.
      ENDIF
      IF ( mflag ) THEN
         CALL mp_gather(psic(1:dffts%nnr), wf)
      ELSE
         nnr = min(size(wf), dffts%nnr)
         wf(1:nnr)=psic(1:nnr)
      ENDIF
   END SUBROUTINE

END MODULE qepy_mod
